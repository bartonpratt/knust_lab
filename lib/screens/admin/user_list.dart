// user_list.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserList extends StatefulWidget {
  UserList({
    Key? key,
  }) : super(key: key);

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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();
    final hospitalId = userData?['hospitalId'] as int?;
    final currentStatus = userData?['status'] as String? ?? 'Not Started';

    try {
      await userDocRef.update({'status': status});
      debugPrint('Your status has been updated to $status');

      final userNotificationsCollection =
          FirebaseFirestore.instance.collection('userNotifications');
      final notificationData = {
        'title': 'Status Update',
        'body': 'Your status has been updated to $status',
        'timestamp': DateTime.now(), // Set the timestamp using DateTime.now()
      };

      // Check if the userNotifications document exists
      userNotificationsCollection.doc(userId).get().then((snapshot) {
        if (snapshot.exists) {
          // Document exists, update the notifications array
          userNotificationsCollection.doc(userId).update({
            'notifications': FieldValue.arrayUnion([notificationData])
          }).then((_) {
            debugPrint('Notification added to user $userId');
            if (status == 'Completed') {
              final doctorNotificationData = {
                'title': 'Doctor Appointment',
                'body': 'You can now go and see the doctor',
                'timestamp': DateTime.now(),
              };
              userNotificationsCollection.doc(userId).update({
                'notifications': FieldValue.arrayUnion([doctorNotificationData])
              }).then((_) {
                debugPrint(
                    'Doctor appointment notification added to user $userId');
              }).catchError((error) {
                debugPrint(
                    'Failed to add doctor appointment notification to user $userId: $error');
              });
            }
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
    } catch (e) {
      debugPrint('Failed to update user $userId status: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (documentSnapshot.exists) {
        final userDetails = documentSnapshot.data();
        debugPrint('User details retrieved successfully: $userDetails');
        return userDetails;
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error retrieving user details: $e');
    }
    return null;
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
              prefixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  // Perform the search here
                },
              ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
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

                  return UserCard(
                    userId: userDoc.id,
                    hospitalId: userData['hospitalId'] as int?,
                    userData: userData,
                    // Pass the notification service to UserCard
                    updateStatus: (newStatus) async {
                      await _updateUserStatus(userDoc.id, newStatus);
                      setState(() {
                        userData['status'] = newStatus;
                      });
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
}

class UserCard extends StatefulWidget {
  final String userId;
  final int? hospitalId;
  final Map<String, dynamic> userData;

  final Function(String) updateStatus;

  UserCard({
    Key? key,
    required this.userId,
    required this.hospitalId,
    required this.userData,
    required this.updateStatus,
  }) : super(key: key);

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  String get status => widget.userData['status'] as String? ?? 'Not Started';
  String selectedStatus = '';

  @override
  void initState() {
    super.initState();
    selectedStatus = status;
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
                onPressed: () async {
                  await widget.updateStatus(selectedStatus);
                  final snackBar = SnackBar(
                    content: Text('Status updated to $selectedStatus'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
