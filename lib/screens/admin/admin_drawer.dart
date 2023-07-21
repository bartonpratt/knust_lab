//admin_drawer.dart
import 'package:flutter/material.dart';
import 'package:knust_lab/screens/authentication_service.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedDrawerIndex;
  final Function(int) onDrawerItemTap;
  final AuthenticationService _authenticationService = AuthenticationService();
  final GlobalKey<ScaffoldState> scaffoldKey;

  AdminDrawer({
    Key? key,
    required this.selectedDrawerIndex,
    required this.onDrawerItemTap,
    required this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              onDrawerItemTap(0);
              scaffoldKey.currentState?.openEndDrawer(); // Close the drawer
            },
            selected: selectedDrawerIndex == 0,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              _authenticationService.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/signin',
                (Route<dynamic> route) => false,
              );
            },
            selected: selectedDrawerIndex == 1,
          ),
        ],
      ),
    );
  }
}
