import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'KOMIKIN_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static Future<String> resolveApiBaseUrl() async {
    if (!kIsWeb) return apiBaseUrl;

    try {
      final response = await http
          .get(Uri.parse('config.json'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return apiBaseUrl;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return apiBaseUrl;

      final value = decoded['apiBaseUrl']?.toString().trim();
      return value == null || value.isEmpty ? apiBaseUrl : value;
    } on TimeoutException {
      return apiBaseUrl;
    } on FormatException {
      return apiBaseUrl;
    } catch (_) {
      return apiBaseUrl;
    }
  }
}
