import 'dart:async';

import 'package:flutter/material.dart';

class DashboardTimer {
  late Timer _timer;
  static DashboardTimer? _instance;

  factory DashboardTimer() {
    _instance ??= DashboardTimer._internal();
    return _instance!;
  }

  DashboardTimer._internal();

  void startTimer(VoidCallback setStateCallback) {
    // Update the timer every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setStateCallback();
    });
  }

  void stopTimer() {
    _timer.cancel();
  }
}
