// user_list.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knust_lab/api/notification_service.dart';

class UserList extends StatefulWidget {
  final FirebaseMessaging firebaseMessaging;
  final NotificationService notificationService;

  const UserList(
      {Key? key,
      required this.firebaseMessaging,
      required this.notificationService})
      : super(key: key);

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
                      _sendUserStatusNotification(userDoc.id, newStatus);
                    },
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
    }).catchError((error) {
      debugPrint('Failed to update user $userId status: $error');
    });
  }

  Future<void> _sendUserStatusNotification(String userId, String status) async {
    try {
      // Fetch the user's FCM token from Firestore
      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userToken = userDocSnapshot.data()?['fcmToken'] as String?;

      if (userToken != null) {
        // Send the notification using the provided notificationService
        await widget.notificationService.showNotification(
          title: 'User Status Update',
          body: 'The status for your account has been updated to: $status',
        );
      }
    } catch (e) {
      print('Error sending user status notification: $e');
    }
  }
}

class UserCard extends StatefulWidget {
  final String userId;
  final int? hospitalId;
  final String status;
  final Function(String) updateStatus;

  const UserCard({
    Key? key,
    required this.userId,
    required this.hospitalId,
    required this.status,
    required this.updateStatus,
  }) : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  String selectedStatus = '';

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.status;
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
