// admin_panel.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:knust_lab/screens/admin/admin_drawer.dart';
import 'package:knust_lab/screens/authentication_service.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({Key? key}) : super(key: key);

  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int _selectedDrawerIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthenticationService _authenticationService = AuthenticationService();
  late StreamSubscription<RemoteMessage> _streamSubscription;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _configureFirebaseMessaging();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  void _configureFirebaseMessaging() {
    _streamSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: $message');
      // Handle foreground messages
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
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
        return UserList(firebaseMessaging: _firebaseMessaging);
      default:
        return Container();
    }
  }
}

class UserList extends StatefulWidget {
  final FirebaseMessaging firebaseMessaging;

  const UserList({Key? key, required this.firebaseMessaging}) : super(key: key);

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'user')
      .snapshots();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchTerm = value.trim();
              });
            },
            decoration: InputDecoration(
              labelText: 'Search by Hospital ID',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchTerm = '';
                  });
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final users = snapshot.data!.docs;

              List<DocumentSnapshot> filteredUsers = users;

              if (_searchTerm.isNotEmpty) {
                filteredUsers = users.where((user) {
                  final userData = user.data() as Map<String, dynamic>;
                  final hospitalId = userData['hospitalId']?.toString() ?? '';
                  return hospitalId.contains(_searchTerm);
                }).toList();
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final userDoc = filteredUsers[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final hospitalId = userData['hospitalId'] as int?;
                  final status = userData['status'] as String? ?? 'Not Started';

                  return UserCard(
                    userId: userDoc.id,
                    hospitalId: hospitalId,
                    status: status,
                    updateStatus: (newStatus) {
                      _updateUserStatus(userDoc.id, newStatus);
                    },
                    firebaseMessaging: widget.firebaseMessaging,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateUserStatus(String userId, String status) {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    userDocRef.update({'status': status}).then((_) {
      debugPrint('Your status has been updated to $status');

      // Add notification to the user's notifications document in the userNotifications collection
      final userNotificationsCollection =
          FirebaseFirestore.instance.collection('userNotifications');
      final notificationData = {
        'title': 'Status Update',
        'body': 'Your status has been updated to $status',
        'timestamp': Timestamp.now(),
      };

      // Check if the userNotifications document exists
      userNotificationsCollection.doc(userId).get().then((snapshot) {
        if (snapshot.exists) {
          // Document exists, update the notifications array
          userNotificationsCollection.doc(userId).update({
            'notifications': FieldValue.arrayUnion([notificationData])
          }).then((_) {
            debugPrint('Notification added to user $userId');
          }).catchError((error) {
            debugPrint('Failed to add notification to user $userId: $error');
          });
        } else {
          // Document doesn't exist, create it and set the notifications array
          userNotificationsCollection.doc(userId).set({
            'notifications': [notificationData]
          }).then((_) {
            debugPrint('Notification added to user $userId');
          }).catchError((error) {
            debugPrint('Failed to add notification to user $userId: $error');
          });
        }
      }).catchError((error) {
        debugPrint('Failed to check userNotifications document: $error');
      });
    }).catchError((error) {
      debugPrint('Failed to update user $userId status: $error');
    });
  }
}

class UserCard extends StatefulWidget {
  final String userId;
  final int? hospitalId;
  final String status;
  final Function(String) updateStatus;
  final FirebaseMessaging firebaseMessaging;

  const UserCard({
    Key? key,
    required this.userId,
    required this.hospitalId,
    required this.status,
    required this.updateStatus,
    required this.firebaseMessaging,
  }) : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.status;
    _configureFirebaseMessaging();
  }

  void _configureFirebaseMessaging() {
    widget.firebaseMessaging.requestPermission();
    widget.firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: $message');
      // Handle foreground messages
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('onMessageOpenedApp: $message');
      // Handle when app is in the background and user taps on the notification
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hospital ID: ${widget.hospitalId ?? ''}',
                  style: const TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedStatus,
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                  items: <String>['Not Started', 'Processing', 'Completed']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  widget.updateStatus(selectedStatus);
                },
                child: const Text('Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
