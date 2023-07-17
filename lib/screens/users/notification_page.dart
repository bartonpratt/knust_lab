// notification_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  List<dynamic> _notifications = [];

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Center(
        child: Text('User not authenticated.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('userNotifications')
            .doc(_user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications =
              snapshot.data?.data()?['notifications'] as List<dynamic>?;

          if (notifications == null || notifications.isEmpty) {
            return const Center(
              child: Text('No notifications found.'),
            );
          }

          _notifications =
              notifications; // Store notifications in the local list

          return ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notificationData =
                  _notifications[index] as Map<String, dynamic>;
              final title = notificationData['title'] as String;
              final body = notificationData['body'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(body),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _clearAllNotifications,
          child: const Text('Clear All'),
        ),
      ),
    );
  }

  void _clearAllNotifications() {
    final userUid = _user?.uid;

    if (userUid != null) {
      FirebaseFirestore.instance
          .collection('userNotifications')
          .doc(userUid)
          .update({'notifications': []}).then((value) {
        setState(() {
          _notifications = []; // Clear the local list of notifications
        });

        // Show a snackbar indicating that notifications were cleared
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications cleared.')),
        );
      }).catchError((error) {
        // Show an error snackbar if there was an issue clearing notifications
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to clear notifications. Please try again.')),
        );
      });
    }
  }
}
