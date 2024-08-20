import 'package:flutter/material.dart';
import 'package:indepthacademy/LoginScreen.dart';
import 'package:indepthacademy/NextScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no_screenshot/no_screenshot.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginCheckScreen extends StatefulWidget {
  @override
  _LoginCheckScreenState createState() => _LoginCheckScreenState();
}

class _LoginCheckScreenState extends State<LoginCheckScreen> {
  final noScreenshot = NoScreenshot.instance;
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    noScreenshot.screenshotOff();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Navigate to the appropriate screen based on login status
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NextScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Loading indicator
    );
  }
}
