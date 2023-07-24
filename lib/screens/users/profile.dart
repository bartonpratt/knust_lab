import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  late Future<Map<String, dynamic>?> _userDetailsFuture;
  String? _tempImageUrl;

  @override
  void initState() {
    super.initState();
    _userDetailsFuture = _getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userDetailsFuture,
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
            body: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Center(
                child: userDetails != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (userDetails['avatarUrl'] != null) {
                                _openProfileImage(context);
                              } else {
                                _selectAndUploadImage(context);
                              }
                            },
                            child: Hero(
                              tag: 'profile_image',
                              child: CircleAvatar(
                                radius: 50.0,
                                backgroundImage: userDetails['avatarUrl'] !=
                                        null
                                    ? NetworkImage(userDetails['avatarUrl']!)
                                    : AssetImage('assets/images/my_image.png')
                                        as ImageProvider<Object>,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          _buildUserInfoCard(
                            icon: Icons.person,
                            title: 'Name',
                            value: userDetails['name'] ?? '',
                          ),
                          _buildUserInfoCard(
                            icon: Icons.email,
                            title: 'Email',
                            value: userDetails['email'] ?? '',
                          ),
                          _buildUserInfoCard(
                            icon: Icons.confirmation_num,
                            title: 'Hospital ID',
                            value: userDetails['hospitalId'] ?? '',
                          ),
                        ],
                      )
                    : const Text('No user details found'),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildUserInfoCard({
    required IconData icon,
    required String title,
    required dynamic value,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getCurrentUser() async {
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
          print('User Details: $userDetails');
          return userDetails;
        } else {
          print('User document does not exist');
        }
      } else {
        print('User is null');
      }

      return null;
    } catch (e) {
      print('Error retrieving current user details: $e');
      return null;
    }
  }

  Future<void> _openProfileImage(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (documentSnapshot.exists) {
        final userDetails = documentSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _tempImageUrl = userDetails['avatarUrl'];
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildProfileImageScreen(),
          ),
        );

        setState(() {
          _tempImageUrl = null;
        });
      }
    }
  }

  Widget _buildProfileImageScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          if (_tempImageUrl == null) {
            _selectAndUploadImage(context);
          }
        },
        child: Center(
          child: _tempImageUrl != null
              ? Hero(
                  tag: 'profile_image',
                  child: Image.network(_tempImageUrl!),
                )
              : const CircularProgressIndicator(),
        ),
      ),
      bottomNavigationBar: _buildEditButton(),
    );
  }

  Widget _buildEditButton() {
    if (_tempImageUrl == null) {
      return SizedBox.shrink();
    }

    return BottomAppBar(
      child: Container(
        color: Colors.black,
        height: 48.0,
        child: TextButton(
          onPressed: () => _selectAndUploadImage(context),
          child: Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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

          // Wait for the upload to complete and get the snapshot
          final TaskSnapshot taskSnapshot = await uploadTask;

          // Check if the upload was successful
          if (taskSnapshot.state == TaskState.success) {
            final String imageUrl = await storageReference.getDownloadURL();
            await _updateUserProfileImage(user.uid, imageUrl);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image uploaded successfully'),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error uploading image'),
            ));
          }
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
