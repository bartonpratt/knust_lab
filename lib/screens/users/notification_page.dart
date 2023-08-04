// notification_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:knust_lab/screens/services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _notificationService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // User is not authenticated, redirect to sign-in page
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacementNamed(context, '/signin');
      });
      return Center();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('userNotifications')
            .doc(_user?.uid) // Show notifications for the current user only
            .snapshots(),
        builder: (context, snapshot) {
          debugPrint("New notification detected");

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

          // Process and show the notifications
          // You can use a Set to avoid showing duplicate notifications
          final Set<String> shownNotifications = Set<String>();
          for (final notificationData in notifications) {
            final title = notificationData['title'] as String;
            final body = notificationData['body'] as String;

            // Check if this notification has already been shown
            final notificationKey = '$title|$body';
            if (!shownNotifications.contains(notificationKey)) {
              shownNotifications.add(notificationKey);

              // Show the notification using Flutter Local Notifications
              _notificationService.showNotification(
                title: title,
                body: body,
              );
            }
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationData =
                  notifications[index] as Map<String, dynamic>;
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
    final userNotificationsCollection =
        FirebaseFirestore.instance.collection('userNotifications');

    // Delete the userNotifications document for the current user
    userNotificationsCollection.doc(_user?.uid).delete().then((_) {
      debugPrint('Notifications cleared.');

      // Show a snackbar indicating that notifications were cleared
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications cleared.')),
      );
    }).catchError((error) {
      debugPrint('Failed to clear notifications: $error');

      // Show a snackbar indicating the error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear notifications.')),
      );
    });
  }
}
