import 'dart:async';

import 'package:flutter/material.dart';

class DashboardTimer {
  late Timer _timer;

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
