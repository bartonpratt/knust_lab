//sign_in.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:knust_lab/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/authentication_service.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final AuthenticationService _authenticationService = AuthenticationService();
  final TextEditingController _hospitalIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TabController _tabController;
  String _errorMessage = '';
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    checkUserLoggedIn();
  }

  Future<void> checkUserLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();
    final isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userDetails = await _authenticationService.getCurrentUser();
      final role = userDetails?['role'];

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  void _handleTabChange() {
    setState(() {
      _errorMessage = ''; // Clear the error message when changing tabs
    });
  }

  Future<void> _signIn() async {
    final hospitalId = int.tryParse(_hospitalIdController.text.trim());
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final selectedIndex = _tabController.index;

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Clear any previous error message
    });

    try {
      if (selectedIndex == 0) {
        // User sign-in logic
        if (hospitalId == null) {
          setState(() {
            _errorMessage = 'Please enter a Valid hospital ID';
            _isLoading = false;
          });

          return;
        }

        final signInResult =
            await _authenticationService.signInWithHospitalId(hospitalId);

        if (signInResult != null) {
          _handleSignInSuccess(signInResult);
        } else {
          setState(() {
            _errorMessage =
                'Invalid Hospital ID!\nPlease enter a valid hospital ID.';
            _isLoading = false;
          });
        }
      } else if (selectedIndex == 1) {
        // Admin sign-in logic
        if (email.isNotEmpty && password.isNotEmpty) {
          final user = await _authenticationService.signInWithEmailAndPassword(
              email, password);

          if (user != null) {
            _handleSignInSuccess(user);
          } else {
            setState(() {
              _errorMessage = 'Invalid email or password';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Please enter email and password';
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      String errorMessage = 'Sign in error: $error';

      // Check if the error is related to a network issue
      if (error is SocketException) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  void _handleSignInSuccess(Map<String, dynamic> userData) async {
    final role = userData['role'];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('isLoggedIn', true);

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _passwordVisible = !_passwordVisible);
  }

  @override
  void dispose() {
    _hospitalIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF22223B),
                Color.fromRGBO(201, 173, 167, 1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 0.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/logo-no.png',
                    width: 100.0,
                    height: 100.0,
                  ),
                  const SizedBox(height: 16.0),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Hello Again!',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(25.0)),
                        child: TabBar(
                          indicator: BoxDecoration(
                              color: customPrimaryColor,
                              borderRadius: BorderRadius.circular(25.0)),
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'User'),
                            Tab(text: 'Admin'),
                          ],
                          onTap: (index) {
                            _handleTabChange(); //clear error message
                          },
                        ),
                      ),
                      SizedBox(
                        height: 250,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSignInForm(
                              controller: _hospitalIdController,
                              labelText: 'Hospital ID',
                            ),
                            _buildAdminSignInForm(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              color: controller.text.isNotEmpty
                  ? Colors.blue // Change to the desired color
                  : Colors.grey,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(5),
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSignInForm() {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              color: _emailController.text.isNotEmpty
                  ? Colors.blue // Change to the desired color
                  : Colors.grey,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: _togglePasswordVisibility,
            ),
            labelStyle: TextStyle(
              color: _passwordController.text.isNotEmpty
                  ? Colors.blue // Change to the desired color
                  : Colors.grey,
            ),
          ),
          obscureText: !_passwordVisible,
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Sign In'),
          ),
        ),
      ],
    );
  }
}
