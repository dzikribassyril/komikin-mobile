import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? AppConfig.apiBaseUrl),
        _timeout = timeout;

  final http.Client _client;
  String _baseUrl;
  final Duration _timeout;

  String get baseUrl => _baseUrl;

  void setBaseUrl(String value) {
    _baseUrl = _normalizeBaseUrl(value);
  }

  Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final response = await _client.get(uri(path)).timeout(_timeout);
      final body = response.body.isEmpty ? '{}' : response.body;
      final decoded = jsonDecode(body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map && decoded['error'] != null
            ? decoded['error'].toString()
            : 'Request failed with status ${response.statusCode}';
        throw ApiException(message, statusCode: response.statusCode);
      }

      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Invalid response format');
      }

      return decoded;
    } on TimeoutException {
      throw const ApiException('Koneksi API terlalu lama merespons');
    } on http.ClientException {
      throw const ApiException('Tidak bisa terhubung ke server API');
    } on FormatException {
      throw const ApiException('Response API tidak valid');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(error.toString());
    }
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/$'), '');
  }
}
