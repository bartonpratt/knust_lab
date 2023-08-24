import 'package:flutter/foundation.dart';

class AuthenticationState extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}

class UserData extends ChangeNotifier {
  Map<String, dynamic>? _userDetails;

  Map<String, dynamic>? get userDetails => _userDetails;

  void updateUserDetails(Map<String, dynamic> userDetails) {
    _userDetails = userDetails;
    notifyListeners();
  }
}
