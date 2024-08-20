import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indepthacademy/LoginScreen.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';

class NextScreen extends StatefulWidget {
  @override
  _NextScreenState createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final noScreenshot = NoScreenshot.instance;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  String _userEmail = '';
  double _progress = 0; // Track the progress of the page loading
  bool _isLoading = true; // Track the loading state
  static const platform = MethodChannel('io.alexmelnyk.utils');

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    WidgetsBinding.instance.addObserver(this);
    noScreenshot.screenshotOff();
    _loadUserEmail();
    _setScreenCaptureProtection(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _setScreenCaptureProtection(false);
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animation = Tween<Offset>(
      begin: Offset(-0.3, -0.3),
      end: Offset(1.3, 1.3),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('userEmail') ?? 'No Email Found';
    });
  }

  Future<void> _setScreenCaptureProtection(bool enable) async {
    try {
      await platform.invokeMethod('preventScreenCapture', {'enable': enable});
    } on PlatformException catch (e) {
      print("Failed to set screen capture protection: '${e.message}'.");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _setScreenCaptureProtection(false);
    } else if (state == AppLifecycleState.resumed) {
      _setScreenCaptureProtection(true);
      noScreenshot.screenshotOff();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading) LinearProgressIndicator(value: _progress),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                        'https://www.in-depth-academy.com/student-yarapatmaged'),
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                        // Removed mediaPlaybackRequiresUserAction as it might not be available
                        ),
                    ios: IOSInAppWebViewOptions(
                      allowsInlineMediaPlayback: true,
                      allowsAirPlayForMediaPlayback: false,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    // Initialize WebView controller if needed
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true; // Show the progress indicator
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() {
                      _isLoading = false; // Hide the progress indicator
                      _progress = 1.0; // Set progress to 100%
                    });
                    // Inject custom controls when the page loads

                    await controller.evaluateJavascript(source: """
                    function injectCustomControls() {
                    var videos = document.querySelectorAll('video');

                           videos.forEach(function(video) {
                    if (video.getAttribute('data-custom-controls-injected') === 'true') return;

      video.controls = false; // Disable native controls

      var customControls = document.createElement('div');
      customControls.id = 'custom-controls';
      customControls.style.position = 'fixed';
      customControls.style.bottom = '10px';
      customControls.style.left = '10px';
      customControls.style.zIndex = '10000';
      customControls.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
      customControls.style.padding = '10px';
      customControls.style.borderRadius = '5px';
      customControls.style.display = 'none'; // Initially hidden
      customControls.innerHTML = `
        <button onclick="playVideo()">Play</button>
        <button onclick="pauseVideo()">Pause</button>
        <button onclick="toggleMute()">Mute</button>
      `;
      document.body.appendChild(customControls);

      window.playVideo = function() {
        video.play();
      }

      window.pauseVideo = function() {
        video.pause();
      }

      window.toggleMute = function() {
        video.muted = !video.muted;
      }

      video.setAttribute('data-custom-controls-injected', 'true');

      // Show controls on click or touch
      video.addEventListener('click', function() {
        customControls.style.display = 'block';
        resetHideControlsTimer();
      });

      // Hide controls after a period of inactivity
      var hideControlsTimer;
      function resetHideControlsTimer() {
        clearTimeout(hideControlsTimer);
        hideControlsTimer = setTimeout(function() {
          customControls.style.display = 'none';
        }, 1000); // Hide after 3 seconds of inactivity
      }

      // Also reset the timer when user interacts with the controls
      customControls.addEventListener('click', function() {
        resetHideControlsTimer();
      });

      // Reset timer when mouse moves or touch events occur
      document.addEventListener('mousemove', resetHideControlsTimer);
      document.addEventListener('touchstart', resetHideControlsTimer);
    });
  }

  // Inject custom controls on page load
  injectCustomControls();

  // Reapply custom controls when new videos are added dynamically
  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.addedNodes.length) {
        injectCustomControls();
      }
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
""");
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100; // Update the progress
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(consoleMessage.message);
                  },
                ),
              ),
            ],
          ),
          _buildAnimatedEmailOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape
        ? null
        : AppBar(
            title: Text('Home'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('isLoggedIn');
                  await prefs.remove('userEmail');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ],
          );
  }

  Widget _buildAnimatedEmailOverlay() {
    return SlideTransition(
      position: _animation,
      child: AnimatedOpacity(
        opacity: 0.2,
        duration: Duration(milliseconds: 3000),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            _userEmail.isNotEmpty ? _userEmail : 'Loading...',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
