import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indepthacademy/LoginScreen.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';

class NextScreen extends StatefulWidget {
  final String returnUrl;
  NextScreen({required this.returnUrl});

  @override
  _NextScreenState createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final noScreenshot = NoScreenshot.instance;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  String _userEmail = '';
  double _progress = 0;
  bool _isLoading = true;
  static const platform = MethodChannel('io.alexmelnyk.utils');
  InAppWebViewController? _webViewController;

  get minutes => null;

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
                    url: WebUri(widget.returnUrl), //widget.returnUrl
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
(function() {
  function injectCustomControls() {
    var videos = document.querySelectorAll('video');

    videos.forEach(function(video) {
      // Ensure videos play inline on iOS
      video.setAttribute('playsinline', '');

      // Disable native controls
      video.controls = false;

      // Check if custom controls have already been injected
      if (video.getAttribute('data-custom-controls-injected') === 'true') return;

      // Create custom controls
      var customControls = document.createElement('div');
      customControls.id = 'custom-controls';
      customControls.style.position = 'absolute';
      customControls.style.bottom = '0px';
      customControls.style.left = '0px';
      customControls.style.width = '100%';
      customControls.style.zIndex = '10000';
      customControls.style.backgroundColor = 'rgba(0, 0, 0, 0.7)';
      customControls.style.padding = '10px';
      customControls.style.borderRadius = '5px';
      customControls.style.display = 'none'; // Initially hidden
      customControls.style.textAlign = 'center'; // Center align controls
      customControls.style.boxSizing = 'border-box'; // Include padding and border in element's total width and height

      customControls.innerHTML = `
        <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
          <button id="play-button" onclick="playVideo()" style="font-size: 24px;">&#9658;</button> <!-- Play Icon -->
          <button id="pause-button" onclick="pauseVideo()" style="font-size: 24px; display: none;">&#10074;&#10074;</button> <!-- Pause Icon -->
          <button onclick="toggleMute()" style="font-size: 24px;">&#128263;</button> <!-- Mute Icon -->
          <input type="range" id="seek-bar" value="0" style="flex-grow: 1; margin: 0 10px; width: auto;">
          <span id="current-time">0:00</span>
        </div>
      `;

      video.parentElement.appendChild(customControls);

      // Custom control functions
      window.playVideo = function() {
        video.play();
        customControls.style.display = 'none'; // Hide controls when video starts playing
        document.getElementById('play-button').style.display = 'none'; // Hide play button
        document.getElementById('pause-button').style.display = 'block'; // Show pause button
      }

      window.pauseVideo = function() {
        video.pause();
        document.getElementById('play-button').style.display = 'block'; // Show play button
        document.getElementById('pause-button').style.display = 'none'; // Hide pause button
      }

      window.toggleMute = function() {
        video.muted = !video.muted;
      }

      // Update seek bar and time display
      var seekBar = customControls.querySelector('#seek-bar');
      var currentTime = customControls.querySelector('#current-time');

      video.addEventListener('timeupdate', function() {
        var duration = video.duration || 0;
        var currentTimeValue = video.currentTime || 0;
        var value = (currentTimeValue / duration) * 100;

        seekBar.value = value;

        var minutes = Math.floor(currentTimeValue / 60);
        var seconds = Math.floor(currentTimeValue % 60);
      
      });

      seekBar.addEventListener('input', function() {
        var value = seekBar.value * video.duration / 100;
        video.currentTime = value;
      });

      // Set flag to prevent duplicate control injection
      video.setAttribute('data-custom-controls-injected', 'true');

      // Show play button when video is paused or not started
      video.addEventListener('pause', function() {
        customControls.style.display = 'block';
        document.getElementById('play-button').style.display = 'block';
        document.getElementById('pause-button').style.display = 'none';
      });

      // Hide play button when video is playing
      video.addEventListener('play', function() {
        customControls.style.display = 'none';
        document.getElementById('play-button').style.display = 'none';
        document.getElementById('pause-button').style.display = 'block';
      });

      // Auto-play video (remove or comment this line if not needed)
      video.play();

      // Show controls on touch or click
      video.addEventListener('click', function() {
        customControls.style.display = 'block';
        resetHideControlsTimer();
      });

      // Hide controls after inactivity
      var hideControlsTimer;
      function resetHideControlsTimer() {
        clearTimeout(hideControlsTimer);
        hideControlsTimer = setTimeout(function() {
          customControls.style.display = 'none';
        }, 1500); // Hide after 3 seconds of inactivity
      }

      // Reset timer when interacting with controls or touching/moving the document
      customControls.addEventListener('click', function() {
        resetHideControlsTimer();
      });
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

})();


""");
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
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
            title: Text(_userEmail),
            actions: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_webViewController != null) {
                    final currentUrl = await _webViewController?.getUrl();
                    if (currentUrl.toString() == widget.returnUrl) {
                      return;
                    }
                    if (await _webViewController!.canGoBack()) {
                      _webViewController!.goBack();
                    } else {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  _webViewController?.loadUrl(
                      urlRequest: URLRequest(url: WebUri(widget.returnUrl)));
                },
              ),
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
