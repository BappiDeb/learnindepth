import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

import 'NextScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _loadingMessage = '';
  bool _hasError = false;

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Starting online mode...';
    });

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
        'packageid':
            'your_packageid_value', // Replace with your actual package ID
        'owner': _emailController.text, // Replace with the owner's actual value
        'requestmode':
            'your_requestmode_value', // Replace with the request mode value
        'machineDetails':
            machineDetails, // Use the device information gathered above
        'email': _emailController.text, // Use the email entered by the user
      };

      final response = await http.post(
        Uri.parse(
            'https://www.in-depth-academy.com/_functions/getvirtualkey_iphone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      final data = jsonDecode(response.body);
      final String message = data['message'] ?? '';
      final bool valid = data['valid'] ?? false;

      if (valid) {
        await _saveLoginStatus(_emailController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NextScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        setState(() {
          _hasError = true;
          _loadingMessage = message.isNotEmpty
              ? message
              : 'An error occurred. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _loadingMessage = 'Error: ${e.toString()}';
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLoginStatus(String email) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
    prefs.setString('userEmail', email);
  }

  Future<void> _clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('isLoggedIn');
    prefs.remove('userEmail');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(_loadingMessage),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 100,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Enter Your Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _fetchData();
                          }
                        },
                        child: Text('Online Mode'),
                      ),
                      if (_hasError) ...[
                        SizedBox(height: 20),
                        Text(
                          _loadingMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
