// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:knust_lab/screens/auth/email_confirmation_page.dart';
import 'package:knust_lab/screens/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knust_lab/screens/splash.dart';
import 'package:knust_lab/screens/auth/sign_in.dart';
import 'package:knust_lab/screens/auth/sign_up.dart';
import 'package:knust_lab/screens/users/dashboard.dart';
import 'package:knust_lab/screens/admin/admin_panel.dart';
import 'package:knust_lab/screens/users/notification_page.dart';
import 'package:knust_lab/screens/users/profile.dart';
import 'package:knust_lab/screens/users/about.dart';
import 'package:cloud_functions/cloud_functions.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize NotificationService
  final notificationService = NotificationService();
  await notificationService.initialize();

  final preferences = await SharedPreferences.getInstance();
  final isLoggedIn = preferences.getBool('isLoggedIn') ?? false;
  String initialRoute = isLoggedIn ? '/splash' : '/signin';

  runApp(MyApp(initialRoute, notificationService));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final NotificationService notificationService = NotificationService();

  MyApp(this.initialRoute, notificationService, {Key? key}) : super(key: key);

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
      navigatorKey: navigatorKey,
      routes: {
        '/splash': (context) => SplashPage(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/email_confirmation': (context) => EmailConfirmationPage(),
        '/dashboard': (context) => DashboardPage(
              notificationService: notificationService,
            ),
        '/admin': (context) => AdminPanelPage(),
        '/notifications': (context) => NotificationPage(),
        '/profile': (context) => ProfilePage(),
        '/about': (context) => AboutPage(),
      },
    );
  }
}
