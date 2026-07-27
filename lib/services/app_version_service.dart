import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:gurukul/main.dart';

class AppVersionService {
  AppVersionService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String?> fetchRequiredVersion() async {
    if (environment == null) {
      debugPrint('App version check skipped: environment is not selected.');
      return null;
    }

    try {
      final response = await _dio.get<dynamic>(
        appVersionUrl,
        options: Options(
          headers: const {'x-api-key': appVersionApiKey},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      debugPrint('App version API Response Status: ${response.statusCode}');
      debugPrint('App version API Response Data: ${response.data}');

      final responseData = _decodeResponse(response.data);
      if (response.statusCode == 200 && responseData != null) {
        final success = responseData['success'] == true;
        final version = responseData['data']?.toString().trim();
        if (success && version != null && version.isNotEmpty) {
          return version;
        }
      }

      debugPrint('App version check returned an invalid response.');
    } on DioException catch (error) {
      debugPrint('App version check failed: ${error.message}');
    } catch (error) {
      debugPrint('App version check failed: $error');
    }

    return null;
  }

  static Map<dynamic, dynamic>? _decodeResponse(dynamic responseData) {
    if (responseData is Map) return responseData;
    if (responseData is String) {
      final decoded = jsonDecode(responseData);
      return decoded is Map ? decoded : null;
    }
    return null;
  }

  static bool versionsMatch(String installedVersion, String requiredVersion) {
    return _normalizeVersion(installedVersion) ==
        _normalizeVersion(requiredVersion);
  }

  static String _normalizeVersion(String version) {
    var normalized = version.trim().toLowerCase();
    if (normalized.startsWith('v')) {
      normalized = normalized.substring(1);
    }

    // PackageInfo.version does not include the build number. Ignore it if the
    // API is later changed to return a value such as 2.0.0+46.
    return normalized.split('+').first;
  }
}
