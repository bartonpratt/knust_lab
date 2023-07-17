//sign_up.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:knust_lab/screens/authentication_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _hospitalIdController = TextEditingController();

  final AuthenticationService _authenticationService = AuthenticationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<bool> _onBackPressed() {
    Navigator.pushReplacementNamed(context, '/signin');
    return Future.value(false); // Prevent default system back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF22223B),
                Color(0xFFC9ADA7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 0.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo-no.png',
                      width: 100.0,
                      height: 100.0,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Create Account!',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _hospitalIdController,
                      decoration: InputDecoration(
                        labelText: 'Hospital ID',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    SizedBox(height: 24.0),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _signUp(context),
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text('Sign Up'),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacementNamed(
                                    context, '/signin');
                              },
                          ),
                        ],
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

  Future<void> _signUp(BuildContext context) async {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String hospitalId = _hospitalIdController.text.trim();

    if (fullName.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        hospitalId.isNotEmpty) {
      if (!isValidFullName(fullName)) {
        _showAlertDialog(
          context,
          'Invalid Full Name',
          'Please enter a valid full name.',
        );
        return;
      }

      if (!isValidEmail(email)) {
        _showAlertDialog(
          context,
          'Invalid Email',
          'Please enter a valid email address.',
        );
        return;
      }

      if (!isValidPassword(password)) {
        _showAlertDialog(
          context,
          'Invalid Password',
          'Password should contain at least 8 characters, including at least one uppercase letter, one lowercase letter, one number, and one special character.',
        );
        return;
      }

      if (!isValidHospitalId(hospitalId)) {
        _showAlertDialog(
          context,
          'Invalid Hospital ID',
          'Please enter a valid hospital ID.',
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final User? user =
          await _authenticationService.signUpWithEmailAndPassword(
              email, password, fullName, int.parse(hospitalId));

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showAlertDialog(
            context, 'Error', 'Failed to sign up. Please try again.');
      }
    } else {
      _showAlertDialog(context, 'Error', 'Please fill in all the fields.');
    }
  }

  bool isValidFullName(String fullName) {
    final String pattern = r'^[a-zA-Z ]+$';
    final RegExp regex = RegExp(pattern);
    return regex.hasMatch(fullName);
  }

  bool isValidEmail(String email) {
    final String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    final String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%\^&\*])(?=.{8,})';
    final RegExp regex = RegExp(pattern);
    return regex.hasMatch(password);
  }

  bool isValidHospitalId(String hospitalId) {
    return hospitalId.length == 5 && int.tryParse(hospitalId) != null;
  }

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
