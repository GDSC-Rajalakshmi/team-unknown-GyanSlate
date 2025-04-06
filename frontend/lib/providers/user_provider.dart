import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  String _userName = "";
  String _userRole = "";
  
  String get userName => _userName;
  String get userRole => _userRole;
  
  void setUserInfo(String name, String role) {
    _userName = name;
    _userRole = role;
    notifyListeners();
  }
} 