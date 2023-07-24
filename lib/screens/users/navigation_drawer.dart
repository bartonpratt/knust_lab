//navigation_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knust_lab/screens/authentication_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

Drawer buildNavigationDrawer(BuildContext context, VoidCallback closeDrawer) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        FutureBuilder<Map<String, dynamic>?>(
          future: _getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Error retrieving user details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              );
            } else {
              final userDetails = snapshot.data;
              return UserAccountsDrawerHeader(
                accountName: Text(
                  userDetails?['name'],
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                accountEmail: Text(
                  userDetails?['email'],
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    closeDrawer();
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: CircleAvatar(
                    backgroundImage: userDetails?['avatarUrl'] != null
                        ? NetworkImage(userDetails?['avatarUrl']!)
                        : AssetImage('assets/images/my_image.png')
                            as ImageProvider<Object>,
                  ),
                ),
              );
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.home),
          title: Text(
            'Home',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          onTap: () {
            closeDrawer(); // Close the drawer
            // Handle home navigation
          },
        ),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text(
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
          leading: Icon(Icons.person),
          title: Text(
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
          leading: Icon(Icons.info),
          title: Text(
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
        Divider(),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text(
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
