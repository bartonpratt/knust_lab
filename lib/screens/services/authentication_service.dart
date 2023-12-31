// authentication_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  Map<String, dynamic>? _cachedUserDetails; // Cache user details

  Future<bool> isAdmin(String email, String password) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty &&
          querySnapshot.docs.first['password'] == password;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    int hospitalId,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        await _saveUserDetails(userId, name, email, hospitalId, role: 'user');

        // Send email verification link to the user
        await userCredential.user!.sendEmailVerification();

        // Return the user
        return userCredential.user;
      }

      return null;
    } catch (e) {
      debugPrint('Sign up error: $e');
      return null;
    }
  }

  Future<void> _saveUserDetails(
    String userId,
    String name,
    String email,
    int hospitalId, {
    String role = 'user',
  }) async {
    final userCollection = _firestore.collection('users');

    final userData = {
      'name': name,
      'email': email,
      'hospitalId': hospitalId,
      'status': 'Not Started',
      'role': role,
    };

    try {
      // Save the user details to Firestore
      await userCollection.doc(userId).set(userData);
      debugPrint('User details saved successfully');

      // Get the FCM token
      final token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Save the FCM token to Firestore
        userData['fcmToken'] = token;
        await userCollection.doc(userId).update(userData);
        print('FCM Token saved successfully');
      }

      // Update isLoggedIn flag in SharedPreferences
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error saving user details: $e');
    }
  }

  Future<Map<String, dynamic>?> signInWithHospitalId(int hospitalId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('hospitalId', isEqualTo: hospitalId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDetails =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint('User Details: $userDetails'); // Print the userDetails map

        final signInResult = await signInWithEmailAndPassword(
            userDetails['email'], userDetails['password']);

        if (signInResult != null) {
          return userDetails; // Return the userDetails map
        }
      }
      return null;
    } catch (e) {
      debugPrint('Sign in with hospital ID error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userDetails = await getCurrentUser();

        if (userDetails != null) {
          final role = userDetails['role'];
          return {'user': userCredential.user, 'role': role};
        }
      }

      return null;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    if (_cachedUserDetails != null) {
      return _cachedUserDetails;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (documentSnapshot.exists) {
        final userDetails = documentSnapshot.data();
        userDetails!['uid'] = userId;
        _cachedUserDetails = userDetails; // Store in cache
        debugPrint('User Details: $userDetails');
        return userDetails;
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error retrieving user details: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final User? user = _firebaseAuth.currentUser;

      if (user != null) {
        return await getUserDetails(user.uid);
      } else {
        debugPrint('User is null');
      }

      return null;
    } catch (e) {
      debugPrint('Error retrieving current user details: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();

      // Reset isLoggedIn flag in SharedPreferences
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('isLoggedIn', false);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Reset password error: $e');
      throw e;
    }
  }
}
