// admin_panel.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:knust_lab/screens/services/notification_service.dart';
import 'package:knust_lab/screens/admin/admin_drawer.dart';
import 'package:knust_lab/screens/services/authentication_service.dart';
import 'package:knust_lab/screens/admin/user_list.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({Key? key}) : super(key: key);

  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int _selectedDrawerIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthenticationService _authenticationService = AuthenticationService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      drawer: AdminDrawer(
        selectedDrawerIndex: _selectedDrawerIndex,
        onDrawerItemTap: (index) {
          setState(() {
            _selectedDrawerIndex = index;
          });
          if (index == 2) {
            _authenticationService.signOut();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/signin',
              (Route<dynamic> route) => false,
            );
          }
          _scaffoldKey.currentState!.openEndDrawer();
        },
        scaffoldKey: _scaffoldKey,
      ),
      body: _getBodyWidget(),
    );
  }

  Widget _getBodyWidget() {
    switch (_selectedDrawerIndex) {
      case 0:
        return UserList(
          firebaseMessaging: _firebaseMessaging,
          notificationService: _notificationService,
        );
      default:
        return Container();
    }
  }
}
