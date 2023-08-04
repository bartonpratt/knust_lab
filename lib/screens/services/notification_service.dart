// notification_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> initialize() async {
    // Initialize Firebase Messaging
    await _firebaseMessaging.requestPermission();

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

  Future<void> initFirebaseMessaging(String userId, String token) async {
    // Unsubscribe the admin from the previous user-specific topic, if any
    await _firebaseMessaging.unsubscribeFromTopic('admin');

    // Validate the topic name
    final RegExp validTopicRegex = RegExp(r'^[a-zA-Z0-9-_.~%]{1,200}$');
    final bool isValidTopic = validTopicRegex.hasMatch('user_$userId');

    if (isValidTopic) {
      // Subscribe to a topic specific to the user
      await _firebaseMessaging.subscribeToTopic('user_$userId');
      print('Subscribed to topic: user_$userId');

      // Update the FCM token in Firestore for the current user
      await updateFCMTokenInFirestore(userId, token);
    } else {
      debugPrint('Invalid topic name: user_$userId');
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
