// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:knust_lab/screens/authentication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knust_lab/api/notification_service.dart';
import 'package:knust_lab/screens/sign_in.dart';
import 'package:knust_lab/screens/sign_up.dart';
import 'package:knust_lab/screens/users/dashboard.dart';
import 'package:knust_lab/screens/admin/admin_panel.dart';
import 'package:knust_lab/screens/users/notification_page.dart';
import 'package:knust_lab/screens/users/profile.dart';
import 'package:knust_lab/screens/users/about.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();

  // Check if the user is already logged in
  final preferences = await SharedPreferences.getInstance();
  final isLoggedIn = preferences.getBool('isLoggedIn') ?? false;
  String initialRoute = isLoggedIn ? '/splash' : '/signin';

  runApp(MyApp(initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp(this.initialRoute);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KNUST Lab',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        primaryColor: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
      ),
      initialRoute: initialRoute,
      navigatorKey: navigatorKey, // Pass the navigatorKey
      routes: {
        '/splash': (context) => SplashPage(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/dashboard': (context) => DashboardPage(),
        '/admin': (context) => AdminPanelPage(),
        '/notifications': (context) => NotificationPage(),
        '/profile': (context) => ProfilePage(),
        '/about': (context) => AboutPage(),
      },
    );
  }
}

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
        navigatorKey.currentState?.pushReplacementNamed('/admin');
      } else {
        navigatorKey.currentState?.pushReplacementNamed('/dashboard');
      }
    } else {
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
