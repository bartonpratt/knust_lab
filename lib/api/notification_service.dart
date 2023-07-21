//notification_service.dart
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
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> initFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle incoming FCM messages while the app is in the foreground
      final notification = message.notification;
      if (notification != null) {
        showNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap action while the app is in the background
      // You can navigate to a specific screen based on the notification payload here
    });
  }

  Future<void> showNotification({
    required String title,
    required String body,
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
  }

  Future<void> updateFCMTokenInFirestore(String userId, String token) async {
    try {
      final userCollection = FirebaseFirestore.instance.collection('users');
      await userCollection.doc(userId).update({'fcmToken': token});
      print('FCM Token updated in Firestore for user: $userId');
    } catch (e) {
      print('Error updating FCM token in Firestore: $e');
    }
  }
}
