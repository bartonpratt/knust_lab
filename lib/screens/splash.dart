// splash.dart

import 'package:flutter/material.dart';
import 'package:knust_lab/main.dart';
import 'package:knust_lab/screens/authentication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthenticationService _authenticationService = AuthenticationService();

  @override
  void initState() {
    super.initState();
    navigateToNextScreen();
  }

  void navigateToNextScreen() async {
    // Simulate a delay for the splash screen
    await Future.delayed(Duration(seconds: 5));

    // Check if the user is already logged in
    final preferences = await SharedPreferences.getInstance();
    final isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userDetails = await _authenticationService.getCurrentUserDetails();
      if (userDetails != null && userDetails['role'] == 'admin') {
        await Future.delayed(
            Duration(seconds: 2)); // Additional delay (optional)
        navigatorKey.currentState?.pushReplacementNamed('/admin');
      } else {
        await Future.delayed(
            Duration(seconds: 2)); // Additional delay (optional)
        navigatorKey.currentState?.pushReplacementNamed('/dashboard');
      }
    } else {
      await Future.delayed(Duration(seconds: 5)); // Additional delay (optional)
      navigatorKey.currentState?.pushReplacementNamed('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
