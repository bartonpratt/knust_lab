// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:knust_lab/screens/auth/authState.dart';
import 'package:knust_lab/screens/auth/email_confirmation_page.dart';
import 'package:knust_lab/screens/services/notification_service.dart';
import 'package:knust_lab/screens/users/dashboard_timer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knust_lab/screens/splash.dart';
import 'package:knust_lab/screens/auth/sign_in.dart';
import 'package:knust_lab/screens/auth/sign_up.dart';
import 'package:knust_lab/screens/users/dashboard.dart';
import 'package:knust_lab/screens/admin/admin_panel.dart';
import 'package:knust_lab/screens/users/notification_page.dart';
import 'package:knust_lab/screens/users/profile.dart';
import 'package:knust_lab/screens/users/about.dart';
import 'colors.dart';

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
  final dashboardTimer = DashboardTimer();
  dashboardTimer.startTimer(() {});

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthenticationState()),
        ChangeNotifierProvider(create: (context) => UserData()),
      ],
      child: MyApp(initialRoute, notificationService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final NotificationService notificationService;

  MyApp(this.initialRoute, this.notificationService, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KNUST Lab',
      theme: ThemeData(
        primarySwatch: customPrimarySwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        primaryColor: customPrimaryColor,
        buttonTheme: const ButtonThemeData(
          textTheme: ButtonTextTheme.primary,
          buttonColor: customPrimaryColor,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: customPrimarySwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        primaryColor: customPrimaryColor,
        buttonTheme: const ButtonThemeData(
          textTheme: ButtonTextTheme.primary,
          buttonColor: customPrimaryColor,
        ),
      ),
      initialRoute: initialRoute,
      navigatorKey: navigatorKey,
      routes: {
        '/splash': (context) => SplashPage(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/email_confirmation': (context) => EmailConfirmationPage(),
        '/dashboard': (context) => DashboardPage(),
        '/admin': (context) => AdminPanelPage(),
        '/notifications': (context) => NotificationPage(),
        '/profile': (context) => ProfilePage(),
        '/about': (context) => AboutPage(),
      },
    );
  }
}
