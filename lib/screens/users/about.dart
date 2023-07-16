import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KNUST Lab',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text('Version: 1.0.0'),
            SizedBox(height: 8.0),
            Text('Developer: Pratt Joseph Barton & Serinye Bright Sumpuo'),
            SizedBox(height: 8.0),
            Text('Index Numbers: 9411519 & 9413219'),
            SizedBox(height: 8.0),
            Text('Email: contact@yourcompany.com'),
            SizedBox(height: 16.0),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
                'KNUST Lab is a comprehensive healthcare tracking application that allows users to manage their medical information, appointments, and prescriptions. With an intuitive interface and powerful features, Meditrack helps users stay organized and informed about their healthcare needs.'),
            SizedBox(height: 16.0),
            Text(
              'Features',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
                '• Personalized dashboard to view medical information at a glance'),
            Text('• Appointment scheduling and reminders'),
            Text('• Prescription tracking and reminders'),
            Text('• Secure storage of medical records'),
            Text('• Notifications for important health updates'),
            Text(
                '• Integration with healthcare providers for seamless data access'),
          ],
        ),
      ),
    );
  }
}
