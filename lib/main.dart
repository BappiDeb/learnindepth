import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:indepthacademy/LoginScreen.dart';
import 'package:indepthacademy/NextScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    noScreenshot.screenshotOff(); // Disable screenshot
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userEmail = prefs.getString('userEmail') ?? '';

    if (isLoggedIn && userEmail.isNotEmpty) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        Map<String, dynamic> machineDetails = {};

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          machineDetails = {
            'brand': androidInfo.brand,
            'hardware': androidInfo.hardware,
            'model': androidInfo.model,
            'manufacturer': androidInfo.manufacturer,
            'osVersion': androidInfo.version.release,
            'platform': 'Android',
          };
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          machineDetails = {
            'brand': iosInfo.name,
            'hardware': iosInfo.utsname.machine,
            'model': iosInfo.model,
            'manufacturer': iosInfo.systemName,
            'osVersion': iosInfo.systemVersion,
            'platform': 'iOS',
          };
        }

        final Map<String, dynamic> requestData = {
          'packageid': 'your_packageid_value',
          'owner': userEmail,
          'action': 'CheckUserOnly',
          'machineDetails': machineDetails,
          'email': userEmail,
        };

        final response = await http.post(
          Uri.parse(
              'https://www.learn-in-depth.com/_functions/getvirtualkey_iphone'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final bool valid = data['valid'] ?? false;
          final String returnUrl = data['returnUrl'] ?? '';

          if (valid) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NextScreen(returnUrl: returnUrl),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid login status.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server error: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
