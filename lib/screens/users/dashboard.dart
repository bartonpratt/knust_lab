//dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:knust_lab/colors.dart';
import 'package:knust_lab/screens/users/dashboard_timer.dart';
import 'navigation_drawer.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage();

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late DashboardTimer dashboardTimer;

  @override
  void initState() {
    super.initState();
    dashboardTimer = DashboardTimer(); // Initialize
  }

  @override
  void dispose() {
    dashboardTimer.stopTimer(); // Stop the timer when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Samples in Queue',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isNotEqualTo: 'admin')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final users = snapshot.data!.docs;

                final currentUserData = users
                    .firstWhereOrNull((user) => user.id == currentUser?.uid)
                    ?.data();

                final otherUsersData = users
                    .where((user) =>
                        user.id != currentUser?.uid &&
                        user.data()['role'] != 'admin')
                    .map((user) => user.data())
                    .toList();

                return Scrollbar(
                  child: ListView(
                    children: [
                      if (currentUserData != null)
                        _buildUserCard(
                          id: 'Hospital ID: ${currentUserData['hospitalId'] ?? ''}',
                          status: currentUserData['status'] ?? 'Not Started',
                          name: currentUserData['name'] ?? '',
                          highlight: true,
                          timerCompletionTimestamp:
                              currentUserData['timerCompletionTimestamp']
                                  ?.toDate(),
                        ),
                      ...otherUsersData
                          .sorted((a, b) =>
                              _getStatusSortValue(a['status']) -
                              _getStatusSortValue(b['status']))
                          .map((userData) => _buildUserCard(
                                id: 'Hospital ID: ${userData['hospitalId'] ?? ''}',
                                status: userData['status'] ?? 'Not Started',
                                name: userData['name'] ?? '',
                                highlight: false,
                                timerCompletionTimestamp:
                                    userData['timerCompletionTimestamp']
                                        ?.toDate(),
                              )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: buildNavigationDrawer(context, () {
        Navigator.pop(context);
      }),
    );
  }

  int _getStatusSortValue(String status) {
    switch (status) {
      case 'Completed':
        return 0;
      case 'Processing':
        return 1;
      case 'Not Started':
        return 2;
      default:
        return 3; // For any other status
    }
  }

  Widget _buildUserCard({
    required String id,
    required String status,
    required String name,
    required bool highlight,
    required DateTime? timerCompletionTimestamp,
  }) {
    Color statusColor = _getStatusColor(status);
    Color backgroundColor =
        highlight ? customPrimaryColor.withOpacity(0.1) : Colors.white;

    if (highlight) {
      return Card(
        elevation: 2.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status == 'Processing' && timerCompletionTimestamp != null)
                _buildCountdownTimer(timerCompletionTimestamp),
              const Text(
                'Current User',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (name.isNotEmpty)
                Text(
                  'Name: $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    id,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2.0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not Started':
        return Colors.red;
      case 'Processing':
        return Colors.yellow;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCountdownTimer(DateTime timerCompletionTimestamp) {
    final now = DateTime.now();
    final timerEndTime = timerCompletionTimestamp;

    if (now.isBefore(timerEndTime)) {
      final remainingDuration = timerEndTime.difference(now);

      final remainingMinutes = remainingDuration.inMinutes;
      final remainingSeconds = remainingDuration.inSeconds % 60;

      final formattedRemainingTime =
          '$remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}';

      return Text(
        'Time left: $formattedRemainingTime',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
      );
    } else {
      return const Text(
        'Results completed',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
      );
    }
  }
}
