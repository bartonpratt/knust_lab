//dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'navigation_drawer.dart';
import 'package:collection/collection.dart';

class DashboardPage extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the navigation drawer
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Samples in Queue',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final users = snapshot.data!.docs;

                final currentUserData = users
                    .firstWhereOrNull((user) => user.id == currentUser?.uid)
                    ?.data();

                final otherUsersData = users
                    .where((user) =>
                        user.id != currentUser?.uid &&
                        user.data()['role'] != 'admin')
                    .map((user) => user.data())
                    .toList();

                return Scrollbar(
                  child: ListView(
                    children: [
                      if (currentUserData != null)
                        _buildUserCard(
                          id: 'Hospital ID: ${currentUserData['hospitalId'] ?? ''}',
                          status: currentUserData['status'] ?? 'Not Started',
                          name: currentUserData['name'] ?? '',
                          highlight: true,
                        ),
                      ...otherUsersData.map((userData) => _buildUserCard(
                            id: 'Hospital ID: ${userData['hospitalId'] ?? ''}',
                            status: userData['status'] ?? 'Not Started',
                            name: userData['name'] ?? '',
                            highlight: false,
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: buildNavigationDrawer(context, () {
        Navigator.pop(context); // Close the drawer
      }),
    );
  }

  Widget _buildUserCard({
    required String id,
    required String status,
    required String name,
    required bool highlight,
  }) {
    Color statusColor = _getStatusColor(status);
    Color backgroundColor =
        highlight ? Colors.blue.withOpacity(0.1) : Colors.white;

    if (highlight) {
      return Card(
        elevation: 2.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: backgroundColor,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current User',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (name.isNotEmpty)
                Text(
                  'Name: $name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    id,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Started':
        return Colors.red;
      case 'Processing':
        return Colors.yellow;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
