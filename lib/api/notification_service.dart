// notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    // Initialize Firebase Messaging
    await _firebaseMessaging.requestPermission();

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> initFirebaseMessaging(String userId) async {
    // Unsubscribe the admin from the previous user-specific topic, if any
    await _firebaseMessaging.unsubscribeFromTopic('admin');

    // Validate the topic name
    final RegExp validTopicRegex = RegExp(r'^[a-zA-Z0-9-_.~%]{1,200}$');
    final bool isValidTopic = validTopicRegex.hasMatch('user_$userId');

    if (isValidTopic) {
      // Subscribe to a topic specific to the user
      await _firebaseMessaging.subscribeToTopic('user_$userId');
    } else {
      debugPrint('Invalid topic name: user_$userId');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? token, // Add the token parameter
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'my_channel_id',
      'My App Notifications',
      channelDescription: 'channel description',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'default',
    );

    // If the token is provided, send the notification to the specific device
    if (token != null) {
      try {
        await _firebaseMessaging.sendMessage(
          data: {
            'title': title,
            'body': body,
          },
          to: token,
        );
      } catch (e) {
        print('Error sending FCM message: $e');
      }
    }
  }

  Future<void> updateFCMTokenInFirestore(String userId, String? token) async {
    if (token != null) {
      try {
        final userCollection = FirebaseFirestore.instance.collection('users');
        await userCollection.doc(userId).update({'fcmToken': token});
        print('FCM Token updated in Firestore for user: $userId');
      } catch (e) {
        print('Error updating FCM token in Firestore: $e');
      }
    } else {
      print('FCM Token is null for user: $userId');
    }
  }
}
