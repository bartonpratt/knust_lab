import 'package:flutter/material.dart';
import 'package:knust_lab/screens/authentication_service.dart';
// Import the SettingsPage

Drawer buildNavigationDrawer(BuildContext context, VoidCallback closeDrawer) {
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
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () {
            closeDrawer(); // Close the drawer
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          onTap: () {
            Navigator.pushNamed(context, '/about');
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: () async {
            AuthenticationService authService = AuthenticationService();
            await authService.signOut();

            // Navigate to the sign-in page
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/signin',
              (Route<dynamic> route) => false,
            );
          },
        ),
      ],
    ),
  );
}
