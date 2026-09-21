import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final String baseUrl;
  final String? fallbackBaseUrl;
  final TokenProvider? tokenProvider;
  final http.Client _httpClient;

  ApiClient({
    String? baseUrl,
    String? fallbackBaseUrl,
    this.tokenProvider,
    http.Client? httpClient,
  })  : baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        fallbackBaseUrl = (fallbackBaseUrl ?? AppConfig.fallbackApiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _httpClient = httpClient ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUri(String hostUrl, String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$hostUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final cleanQuery = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null) {
        cleanQuery[key] = value.toString();
      }
    });
    return uri.replace(queryParameters: cleanQuery);
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send((host) async {
      final uri = _buildUri(host, path, queryParameters);
      final headers = await _headers();
      return _httpClient.get(uri, headers: headers).timeout(AppConfig.requestTimeout);
    });
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send((host) async {
      final uri = _buildUri(host, path, queryParameters);
      final headers = await _headers();
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient
          .post(uri, headers: headers, body: encodedBody)
          .timeout(AppConfig.requestTimeout);
    });
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send((host) async {
      final uri = _buildUri(host, path, queryParameters);
      final headers = await _headers();
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(AppConfig.requestTimeout);
    });
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send((host) async {
      final uri = _buildUri(host, path, queryParameters);
      final headers = await _headers();
      final encodedBody = body != null ? jsonEncode(body) : null;
      return _httpClient
          .put(uri, headers: headers, body: encodedBody)
          .timeout(AppConfig.requestTimeout);
    });
  }

  Future<void> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _send((host) async {
      final uri = _buildUri(host, path, queryParameters);
      final headers = await _headers();
      return _httpClient.delete(uri, headers: headers).timeout(AppConfig.requestTimeout);
    });
  }

  Future<dynamic> _send(Future<http.Response> Function(String host) requestFn) async {
    try {
      final response = await requestFn(baseUrl);
      return _handleResponse(response);
    } catch (e) {
      if (fallbackBaseUrl != null &&
          fallbackBaseUrl!.isNotEmpty &&
          fallbackBaseUrl != baseUrl) {
        try {
          final fallbackResponse = await requestFn(fallbackBaseUrl!);
          return _handleResponse(fallbackResponse);
        } catch (_) {}
      }

      if (e is ApiException) rethrow;
      if (e is SocketException) {
        throw ApiException(
          statusCode: 0,
          message: 'Unable to connect to backend server. Please verify network or server status.',
          details: e.message,
        );
      }
      if (e is TimeoutException) {
        throw const ApiException(
          statusCode: 408,
          message: 'Request timed out. The server may be waking up, please retry.',
        );
      }
      if (e is http.ClientException) {
        throw ApiException(
          statusCode: 0,
          message: 'Network request failed: ${e.message}',
          details: e,
        );
      }
      throw ApiException(
        statusCode: 0,
        message: 'Unexpected network error: $e',
        details: e,
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty || response.statusCode == 204) {
        return null;
      }
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String errorMessage = 'Request failed with status code ${response.statusCode}';
    dynamic errorDetails;

    if (response.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(response.body);
        errorDetails = parsed;
        if (parsed is Map<String, dynamic>) {
          if (parsed['detail'] is String) {
            errorMessage = parsed['detail'] as String;
          } else if (parsed['detail'] is List) {
            final details = parsed['detail'] as List;
            if (details.isNotEmpty && details.first is Map && details.first['msg'] != null) {
              errorMessage = details.first['msg'].toString();
            } else {
              errorMessage = parsed['detail'].toString();
            }
          } else if (parsed['message'] is String) {
            errorMessage = parsed['message'] as String;
          }
        }
      } catch (_) {
        errorMessage = response.body;
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      details: errorDetails,
    );
  }
}
