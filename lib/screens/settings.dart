// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool isDarkThemeEnabled;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      isDarkThemeEnabled = preferences.getBool('isDarkThemeEnabled') ?? false;
    });
  }

  Future<void> _toggleDarkTheme(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    setState(() {
      isDarkThemeEnabled = value;
    });
    preferences.setBool('isDarkThemeEnabled', value);
    // You can also update the theme of the app here based on the value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dark Theme',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SwitchListTile(
              title: const Text('Enable Dark Theme'),
              value: isDarkThemeEnabled,
              onChanged: (value) {
                _toggleDarkTheme(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
