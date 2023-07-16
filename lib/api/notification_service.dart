//notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void> initialize(BuildContext context) async {
    // Initialize Firebase Messaging
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Configure Firebase Messaging callbacks
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: $message');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('onMessageOpenedApp: $message');
      // Handle when app is in the background and user taps on the notification
      // Navigate to the appropriate screen based on the notification data
      // For example:
      Navigator.pushReplacementNamed(context, '/notifications');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notificationData = message.notification;
    final title = notificationData?.title ?? '';
    final body = notificationData?.body ?? '';

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
  }
}
