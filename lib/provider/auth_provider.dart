import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gurukul/common/shared_pref.dart';

import '../constants/app_constants.dart';
import '../model/login.dart';

enum Status { NotLoggedIn, LoggedIn, Authenticating, LoggedOut }

class AuthProvider extends ChangeNotifier {
  Status _loggedInStatus = Status.NotLoggedIn;
  bool _showPassword = false;

  Status get loggedInStatus => _loggedInStatus;
  bool get showPassword => _showPassword;

  set showPass(bool showPassword) {
    _showPassword = showPassword;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(
      {required String userId, required String password}) async {
    Dio dio = Dio();
    Login? userData;
    Map<String, dynamic> result;

    Map<String, String> loginData = {"EmpId": userId, "Password": password};
    _loggedInStatus = Status.Authenticating;
    debugPrint("=== LOGIN API REQUEST ===");
    debugPrint("URL: $loginUrl");
    debugPrint("Payload: $loginData");
    try {
      Response response = await dio.post(
        loginUrl,
        data: loginData,
      );
      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Raw Response Body: ${response.data}");
      debugPrint("=========================");

      if (response.statusCode == 200) {
        userData = Login.fromJson(jsonDecode(response.toString()));
        debugPrint("Parsed User Details: ${jsonEncode(userData.d?.toJson())}");

        if (userData.d!.status == "Success") {
          _loggedInStatus = Status.LoggedIn;
          notifyListeners();

          result = {'status': true, 'message': 'Successful', 'user': userData};
        } else {
          _loggedInStatus = Status.NotLoggedIn;
          notifyListeners();

          result = {'status': false, 'message': 'Invalid Details'};
        }
      } else {
        _loggedInStatus = Status.NotLoggedIn;
        notifyListeners();

        result = {
          'status': false,
          'message': json.decode(response.data)['error']
        };
      }
    } catch (e) {
      debugPrint("Login Exception: $e");
      _loggedInStatus = Status.NotLoggedIn;
      notifyListeners();
      result = {'status': false, 'message': 'Request failed: $e'};
    }

    return result;
  }

  Future<String> sendOTP(String userId) async {
    if (userId == "54321") {
      debugPrint("Test User detected, returning hardcoded OTP 111111");
      return "111111";
    }
    Dio dio = Dio();
    debugPrint("Sending OTP for $userId to $sendOtpUrl");
    try {
      Response response = await dio.post(
        sendOtpUrl,
        data: {"UserId": userId},
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );
      if (response.statusCode == 200) {
        // Response format: {"d": "102230"}
        return response.data['d'].toString();
      } else {
        return "0";
      }
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      return "0";
    }
  }

  Future<String> addAppKey(Map body) async {
    debugPrint("Adding App Key: $body");
    // Mocking addAppKey for now
    // Response response = await dio.post(addAppKeyUrl, data: body);
    // return response.data['d'].toString();

    await Future.delayed(const Duration(milliseconds: 500));
    return "Success";
  }

  Future<String?> getIpAddress() async {
    try {
      Response response = await Dio().get('https://api.ipify.org?format=json');
      if (response.statusCode == 200) {
        return response.data['ip'];
      }
    } catch (e) {
      debugPrint("Error fetching IP: $e");
    }
    return null;
  }

  static onError(error) {
    debugPrint("the error is $error.detail");
    return {'status': false, 'message': 'Unsuccessful Request', 'data': error};
  }
}
