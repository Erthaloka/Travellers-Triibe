/// File: api_client.dart
/// Purpose: Single HTTP handler with JWT interceptor
/// Context: Used by all services for API calls

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../storage/secure_storage.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, int statusCode) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure(ApiError error, int statusCode) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// API Error model
class ApiError {
  final String code;
  final String message;

  ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return ApiError(
        code: error['code'] ?? 'UNKNOWN_ERROR',
        message: error['message'] ?? 'An unknown error occurred',
      );
    }
    return ApiError(
      code: 'UNKNOWN_ERROR',
      message: error?.toString() ?? 'An unknown error occurred',
    );
  }

  factory ApiError.network() {
    return ApiError(
      code: 'NETWORK_ERROR',
      message: 'Unable to connect. Please check your internet connection.',
    );
  }

  factory ApiError.timeout() {
    return ApiError(
      code: 'TIMEOUT_ERROR',
      message: 'Request timed out. Please try again.',
    );
  }

  factory ApiError.unknown([String? message]) {
    return ApiError(
      code: 'UNKNOWN_ERROR',
      message: message ?? 'An unexpected error occurred',
    );
  }

  @override
  String toString() => message;
}

/// Exception for API errors
class ApiException implements Exception {
  final ApiError error;
  final int statusCode;

  ApiException(this.error, this.statusCode);

  @override
  String toString() => error.message;
}

/// Main API Client - handles all HTTP requests
class ApiClient {
  final http.Client _httpClient;
  final SecureStorage _secureStorage;
  final String _baseUrl;

  ApiClient({
    http.Client? httpClient,
    required SecureStorage secureStorage,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage,
        _baseUrl = baseUrl ?? Env.baseUrl;

  /// GET request
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _request(
      'GET',
      endpoint,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  /// POST request
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _request(
      'POST',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  /// PUT request
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _request(
      'PUT',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  /// DELETE request
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return _request(
      'DELETE',
      endpoint,
      requiresAuth: requiresAuth,
    );
  }

  /// Core request handler
  Future<ApiResponse<Map<String, dynamic>>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      // Build URI
      Uri uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Build headers
      final headers = await _buildHeaders(requiresAuth);

      // Make request
      http.Response response;
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw ApiException(ApiError.unknown('Invalid HTTP method'), 500);
      }

      // Parse response
      return _parseResponse(response);
    } on http.ClientException {
      return ApiResponse.failure(ApiError.network(), 0);
    } on TimeoutException {
      return ApiResponse.failure(ApiError.timeout(), 0);
    } on FormatException catch (e) {
      return ApiResponse.failure(ApiError.unknown('Invalid response format: ${e.message}'), 500);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') || errorStr.contains('Connection')) {
        return ApiResponse.failure(ApiError.network(), 0);
      }
      return ApiResponse.failure(ApiError.unknown(errorStr), 500);
    }
  }

  /// Build request headers
  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Parse HTTP response
  ApiResponse<Map<String, dynamic>> _parseResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (response.body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success({}, statusCode);
      } else {
        return ApiResponse.failure(
          ApiError(code: 'EMPTY_RESPONSE', message: 'Server returned empty response'),
          statusCode,
        );
      }
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return ApiResponse.failure(
        ApiError(code: 'PARSE_ERROR', message: 'Failed to parse server response'),
        statusCode,
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.success(data, statusCode);
    }

    // Handle specific status codes
    switch (statusCode) {
      case 401:
        return ApiResponse.failure(
          ApiError(code: 'UNAUTHORIZED', message: 'Session expired. Please login again.'),
          statusCode,
        );
      case 403:
        return ApiResponse.failure(
          ApiError(code: 'FORBIDDEN', message: 'You do not have permission to perform this action.'),
          statusCode,
        );
      case 404:
        return ApiResponse.failure(
          ApiError(code: 'NOT_FOUND', message: 'Resource not found.'),
          statusCode,
        );
      case 422:
        return ApiResponse.failure(
          ApiError.fromJson(data),
          statusCode,
        );
      case 429:
        return ApiResponse.failure(
          ApiError(code: 'RATE_LIMITED', message: 'Too many requests. Please try again later.'),
          statusCode,
        );
      case 500:
      case 502:
      case 503:
        return ApiResponse.failure(
          ApiError(code: 'SERVER_ERROR', message: 'Server error. Please try again later.'),
          statusCode,
        );
      default:
        return ApiResponse.failure(
          ApiError.fromJson(data),
          statusCode,
        );
    }
  }

  /// Dispose client
  void dispose() {
    _httpClient.close();
  }
}
