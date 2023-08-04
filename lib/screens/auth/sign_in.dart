//sign_in.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:knust_lab/screens/auth/sign_up.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/authentication_service.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthenticationService _authenticationService = AuthenticationService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    checkUserLoggedIn();
  }

  Future<void> checkUserLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();
    final isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userDetails = await _authenticationService.getCurrentUser();
      if (userDetails != null && userDetails['role'] == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        final user = await _authenticationService.signInWithEmailAndPassword(
          email,
          password,
        );

        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setBool('isLoggedIn', true);

          final role = user['role'];

          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid email or password';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Please enter email and password';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign in error: $error';
      });
    }
  }

  void _resetPassword(BuildContext context) {
    TextEditingController _emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset Password'),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Enter your email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    // Call the function to reset the password
                    await _authenticationService.resetPassword(email);
                    Navigator.pop(context); // Close the dialog
                    _showSnackBar(context, 'Password reset email sent.');
                  } catch (e) {
                    print('Error sending password reset email: $e');
                    _showSnackBar(context,
                        'Error sending reset email. Please try again.');
                  }
                } else {
                  _showSnackBar(context, 'Please enter your email.');
                }
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop(); // Close the app
        return false; // Prevent further navigation
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/logo-no.png',
                        width: 100.0,
                        height: 100.0,
                      ),
                      SizedBox(height: 16.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Hello Again!',
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 8.0),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_passwordVisible,
                          ),
                          SizedBox(height: 16.0),
                          // Add "Forgot Password" link here
                          SizedBox(height: 16.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => _resetPassword(context),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              child: _isLoading
                                  ? CircularProgressIndicator()
                                  : Text('Sign In'),
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.black),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignUpPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage.isNotEmpty)
                            Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}