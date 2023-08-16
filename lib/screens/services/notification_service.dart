// notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:knust_lab/screens/authentication_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize Firebase Messaging
    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Set up Firebase onMessage callback
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final title = data['title'] ?? 'Notification';
      final body = data['body'] ?? 'You have a new notification';
      showNotification(title: title, body: body);
    });

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Get the FCM token and update it in Firestore
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await updateFCMTokenInFirestore(userId, token);
        }
      } else {
        debugPrint('FCM Token is null');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    final data = message.data;
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? 'You have a new notification';
    showNotification(title: title, body: body);
  }

  Future<void> sendStatusUpdateNotification({
    required String userId,
    required String newStatus,
  }) async {
    try {
      final user = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userName = user['name'] ?? 'User';

      final statusUpdateMessage =
          'Hello $userName, your status has been updated to $newStatus';

      await sendUserNotification(
        userId: userId,
        data: {
          'title': 'Status Update',
          'body': statusUpdateMessage,
          // Include additional custom data here if needed
        },
      );
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  Future<void> sendUserNotification({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final serverKey =
        'AAAAymXn9CY:APA91bFo6Ka9WUAdQvXEXRG6wtTol0lix9GTwaZyy6l7o-R1VQ74LO-ctvaTMK_kO60xfgyH9DkhwzYiUrbJgex3nTpKCQU-mbeMEy1uxGR9Rfh4Om0PfO1hrinmfoNNBrJ8WYKuS6gk';

    final user =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userFCMToken = user['fcmToken'] as String?;

    print('User FCM Token being used: $userFCMToken');
    if (userFCMToken != null) {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': userFCMToken,
          'data': data, // Send the data payload
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM message sent successfully');
      } else {
        debugPrint('Failed to send FCM message: ${response.statusCode}');
      }
    } else {
      debugPrint('User FCM Token is null for user: $userId');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'knust_lab_channel',
      'KNUST Lab Channel',
      channelDescription: 'Channel for KNUST Lab Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      debugPrint('Showing notification: Title - $title, Body - $body');
      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'default',
      );
      debugPrint('Notification shown.');
    } catch (e) {
      debugPrint('Error showing notification: $e');
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
