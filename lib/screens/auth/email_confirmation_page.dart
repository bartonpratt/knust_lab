// email_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent/android_intent.dart';

class EmailConfirmationPage extends StatefulWidget {
  @override
  _EmailConfirmationPageState createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null && !_user!.emailVerified) {
      _sendEmailVerification();
    }
  }

  Future<void> _sendEmailVerification() async {
    await _user!.sendEmailVerification();
    setState(() {});
  }

  Future<void> _resendEmailVerification() async {
    await _user!.sendEmailVerification();
    setState(() {});
  }

  void _openEmailApp() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      // If the device is an Android device, use android_intent to open Gmail directly
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.google.android.gm', // Package name for Gmail app
        category: 'android.intent.category.APP_EMAIL',
      );

      try {
        await intent.launch();
      } catch (e) {
        print('Error opening Gmail: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Gmail app.'),
          ),
        );
      }
    } else {
      // For iOS or other platforms, use url_launcher to open the default mail app
      final emailUri = Uri(
        scheme: 'mailto',
        path: _user?.email ?? '',
      );
      final emailUrl = emailUri.toString();

      if (await canLaunch(emailUrl)) {
        await launch(emailUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No email app is installed on this device.'),
          ),
        );
      }
    }
  }

  // Handle the back button press
  Future<bool> _onBackPressed() async {
    // Sign out the user before navigating to the sign-in page
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacementNamed(context, '/signin');
    return true; // Prevent default system back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/mail.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Spacer(),
                    Icon(
                      Icons.email,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 100),
                    Text(
                      'Confirm your email',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We have sent an email to ${_user?.email ?? ''}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openEmailApp,
                        child: Text(
                          'Open email app',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resendEmailVerification,
                        child: Text(
                          "I didn't receive my email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black
                              .withOpacity(0.6), // Set black with 60% opacity
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                        child: Text(
                          'Continue to Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
