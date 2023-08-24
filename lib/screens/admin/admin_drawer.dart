//admin_drawer.dart
import 'package:flutter/material.dart';
import 'package:knust_lab/colors.dart';
import 'package:knust_lab/screens/services/authentication_service.dart';

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
          DrawerHeader(
            decoration: const BoxDecoration(
              color: customPrimaryColor, // Set your desired background color
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo-no.png', // Replace with your logo image path
                    width: 80, // Adjust the width as needed
                    height: 80, // Adjust the height as needed
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'KNUST Lab',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
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
