import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup FlutterMethodChannel
    let controller = window?.rootViewController as! FlutterViewController
    let inAppWebViewChannel = FlutterMethodChannel(name: "io.alexmelnyk.utils", binaryMessenger: controller.binaryMessenger)

    inAppWebViewChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      // Handle method calls from Dart
      switch call.method {
      case "preventScreenCapture":
        guard let args = call.arguments as? Dictionary<String, Any>,
              let enable = args["enable"] as? Bool else {
          result(FlutterError(code: "-14", message: "Missing parameters", details: "Missing parameter 'enable'"))
          return
        }
        self.setScreenCaptureProtection(enable: enable)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Add observer for screen capture changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(secureScreen),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func secureScreen() {
    if UIScreen.main.isCaptured {
      // Block the content by overlaying a view
      if self.window?.rootViewController?.view.viewWithTag(98765) == nil {
        let blockView = UIView(frame: UIScreen.main.bounds)
        blockView.backgroundColor = .black
        blockView.tag = 98765 // Arbitrary tag to identify the view
        self.window?.rootViewController?.view.addSubview(blockView)
      }
    } else {
      // Remove the blocking view
      self.window?.rootViewController?.view.viewWithTag(98765)?.removeFromSuperview()
    }
  }

  func setScreenCaptureProtection(enable: Bool) {
    NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    if enable {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(secureScreen),
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}