// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatelessWidget {
  final ImagePicker _imagePicker = ImagePicker();

  ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCurrentUserDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
            ),
            body: const Center(
              child: Text('Error retrieving user details'),
            ),
          );
        } else {
          final userDetails = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
            ),
            body: Center(
              child: userDetails != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _selectAndUploadImage(context),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                              userDetails['avatarUrl'] ?? '',
                            ),
                            radius: 50.0,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        _buildUserInfoItem(
                          Icons.person,
                          'Name',
                          userDetails['name'] ?? '',
                        ),
                        _buildUserInfoItem(
                          Icons.email,
                          'Email',
                          userDetails['email'] ?? '',
                        ),
                        _buildUserInfoItem(
                          Icons.confirmation_num,
                          'Hospital ID',
                          userDetails['hospitalId'] ?? '',
                        ),
                      ],
                    )
                  : const Text('No user details found'),
            ),
          );
        }
      },
    );
  }

  Widget _buildUserInfoItem(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8.0),
          Text(
            '$title: ${value.toString()}',
            style: const TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getCurrentUserDetails() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final DocumentSnapshot documentSnapshot = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (documentSnapshot.exists) {
          final userDetails = documentSnapshot.data() as Map<String, dynamic>;
          debugPrint('User Details: $userDetails');
          return userDetails;
        } else {
          debugPrint('User document does not exist');
        }
      } else {
        debugPrint('User is null');
      }

      return null;
    } catch (e) {
      debugPrint('Error retrieving current user details: $e');
      return null;
    }
  }

  Future<void> _selectAndUploadImage(BuildContext context) async {
    final XFile? selectedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      final File imageFile = File(selectedImage.path);

      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final Reference storageReference = FirebaseStorage.instance
              .ref()
              .child('profile_images/${user.uid}');
          final UploadTask uploadTask = storageReference.putFile(imageFile);
          await uploadTask.whenComplete(() async {
            final String imageUrl = await storageReference.getDownloadURL();
            await _updateUserProfileImage(user.uid, imageUrl);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image uploaded successfully'),
            ));
          });
        }
      } catch (e) {
        debugPrint('Image upload error: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error uploading image'),
        ));
      }
    }
  }

  Future<void> _updateUserProfileImage(String userId, String imageUrl) async {
    final userDocument =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await userDocument.update({
      'avatarUrl': imageUrl,
    });
  }
}
