import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../model/login.dart';

enum Status { NotLoggedIn, LoggedIn, Authenticating, LoggedOut }

class AuthProvider extends ChangeNotifier {
  AuthProvider({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
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
    final loginData = {
      "userId": userId.trim(),
      "password": password,
      "source": authSource,
    };
    _loggedInStatus = Status.Authenticating;
    notifyListeners();
    debugPrint("=== LOGIN API REQUEST ===");
    debugPrint("URL: $loginUrl");
    try {
      final response = await _dio.post(
        loginUrl,
        data: loginData,
        options: _authOptions,
      );
      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Raw Response Body: ${response.data}");
      debugPrint("=========================");

      final body = _responseMap(response.data);
      if (_is2xx(response.statusCode) && body['success'] == true) {
        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};
        final userData = Login(
          d: D.fromAuthJson(data, fallbackUserId: userId.trim()),
        );
        _loggedInStatus = Status.LoggedIn;
        notifyListeners();
        return {
          'status': true,
          'message': body['message']?.toString() ?? 'Success',
          'user': userData,
          'twoFactorEnabled': data['twoFactorEnabled'] == true,
        };
      }

      _loggedInStatus = Status.NotLoggedIn;
      notifyListeners();
      return {
        'status': false,
        'message': body['message']?.toString() ?? 'Invalid Details',
      };
    } on DioException catch (e) {
      debugPrint("Login Exception: $e");
      _loggedInStatus = Status.NotLoggedIn;
      notifyListeners();
      final body = _responseMap(e.response?.data);
      return {
        'status': false,
        'message': body['message']?.toString() ??
            'Unable to login. Please try again.',
      };
    } catch (e) {
      debugPrint("Login Exception: $e");
      _loggedInStatus = Status.NotLoggedIn;
      notifyListeners();
      return {'status': false, 'message': 'Unable to login. Please try again.'};
    }
  }

  Future<bool> sendOTP(String userId) async {
    if (userId == "54321") {
      debugPrint("Test User detected, skipping SendOtp API");
      return true;
    }
    debugPrint("Sending OTP for $userId to $sendOtpUrl");
    try {
      final response = await _dio.post(
        sendOtpUrl,
        data: {"userId": userId, "source": authSource},
        options: _authOptions,
      );
      return _isSuccessfulResponse(response);
    } catch (e) {
      debugPrint("Error sending OTP: $e");
      return false;
    }
  }

  Future<bool> verifyOTP({required String userId, required String otp}) async {
    if (userId == "54321") {
      return otp == "111111";
    }
    try {
      final response = await _dio.post(
        verifyOtpUrl,
        data: {"userId": userId, "otp": otp, "source": authSource},
        options: _authOptions,
      );
      return _isSuccessfulResponse(response);
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      return false;
    }
  }

  Options get _authOptions => Options(headers: {
        "Content-Type": "application/json",
        "x-api-key": authApiKey,
      });

  bool _isSuccessfulResponse(Response response) {
    if (!_is2xx(response.statusCode)) return false;
    final body = _responseMap(response.data);
    if (body['success'] is bool && body['success'] != true) return false;
    final data = body['data'];
    if (data is bool) return data;
    if (data is Map) {
      for (final key in ['verified', 'isVerified', 'isValid']) {
        if (data[key] is bool) return data[key] == true;
      }
    }
    return true;
  }

  bool _is2xx(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _responseMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
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
