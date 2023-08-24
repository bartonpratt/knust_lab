import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knust_lab/colors.dart';
import 'package:knust_lab/screens/services/authentication_service.dart';

Drawer buildNavigationDrawer(BuildContext context, VoidCallback closeDrawer) {
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
                SizedBox(height: 10),
                Text(
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
          title: const Text(
            'Home',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          onTap: () {
            closeDrawer(); // Close the drawer
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          onTap: () {
            closeDrawer(); // Close the drawer
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          onTap: () {
            closeDrawer(); // Close the drawer
            Navigator.pushNamed(context, '/profile');
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          onTap: () {
            closeDrawer(); // Close the drawer
            Navigator.pushNamed(context, '/about');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          onTap: () async {
            AuthenticationService authService = AuthenticationService();
            await authService.signOut();

            closeDrawer(); // Close the drawer

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

Future<Map<String, dynamic>?> _getCurrentUser() async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (documentSnapshot.exists) {
        final userDetails = documentSnapshot.data() as Map<String, dynamic>;
        print('User Details: $userDetails');
        return userDetails;
      } else {
        print('User document does not exist');
      }
    } else {
      print('User is null');
    }

    return null;
  } catch (e) {
    print('Error retrieving current user details: $e');
    return null;
  }
}
