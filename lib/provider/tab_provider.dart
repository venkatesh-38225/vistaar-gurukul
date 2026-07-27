import 'dart:async';

import 'package:flutter/material.dart';

class TabProvider extends ChangeNotifier {
  int tabs = 0;
  List<int> _opSelected = [];
  List<int> _qId = [];
  bool _showAppBar = true;
  bool _isFromCompleted = false;
  List? photos = [];
  int _photoPage = 0;
  bool _canMovePage = false;
  int _countdownValue = 5;
  // final int _currentPdfPage = 0;

  List<int> get opSelected => _opSelected;
  List<int> get qId => _qId;

  int get currentTab => tabs;
  bool get showAppBar => _showAppBar;

  bool get isFromCompleted => _isFromCompleted;
  List get getPhotos => photos!;
  int get photoPage => _photoPage;

  bool get canMovePage => _canMovePage;

  Timer? _countdownTimer;

  int get countdownValue => _countdownValue;

  void startCountdown() {
    _countdownValue = 5;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      debugPrint("countdown = $_countdownTimer");
      notifyListeners();
      if (_countdownValue <= 0) {
        timer.cancel();
      }
    });
  }

  set newTab(int tab) {
    tabs = tab;

    notifyListeners();
  }

  set setOpSelected(int optionS) {
    debugPrint("adding option: $optionS");
    _opSelected.add(optionS + 1);
    notifyListeners();
  }

  set setQID(int qId) {
    _qId.add(qId);
    notifyListeners();
  }

  void resetSelection() {
    _opSelected = [];
    _qId = [];
    notifyListeners();
  }

  set setShowAppBar(bool showAppBar) {
    _showAppBar = showAppBar;
    notifyListeners();
  }

  set setIsFromCompleted(bool fromCompleted) {
    _isFromCompleted = fromCompleted;
    notifyListeners();
  }

  set setCanMovePage(bool canMove) {
    debugPrint("canmOve = $canMove");
    _canMovePage = canMove;
    notifyListeners();
  }

  void reset() {
    tabs = 0;
    _opSelected = [];
    _qId = [];
    _showAppBar = true;
    notifyListeners();
  }

  set addPhotos(Map imagePath) {
    photos!.add(imagePath);
  }

  set setPhotoPage(int pageIndex) {
    _photoPage = pageIndex;
    notifyListeners();
  }

  // set setCurrentPage(int page) {}

  void clearPhotos() {
    debugPrint("clearing photos");
    if (photos!.isNotEmpty && photos != null) {
      photos!.clear();
    }
    _photoPage = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
