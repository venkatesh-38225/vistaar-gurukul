import 'package:flutter/material.dart';

class ThemeChanger with ChangeNotifier {
  bool _isNightMode = false;

  bool get isNightMode => _isNightMode;

  set setIsNightMode(bool nightMode) {
    _isNightMode = nightMode;
    notifyListeners();
  }
}
