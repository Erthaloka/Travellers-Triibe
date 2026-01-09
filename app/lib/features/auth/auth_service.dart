/// Auth service for authentication API calls
library;

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/text_normalizer.dart';
import 'models/account.dart';

/// Authentication service - handles all auth-related API calls
class AuthService {
  final ApiClient _apiClient;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Send OTP to phone number
  Future<OtpResponse> sendOtp({
    required String email,
    required String phone,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendOtp,
      body: {'email': normalizeEmail(email), 'phone': normalizePhone(phone)},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      return OtpResponse.fromJson(response.data!);
    }

    return OtpResponse(
      success: false,
      message: response.error?.message ?? 'Failed to send OTP',
    );
  }

  /// Verify OTP and login
  Future<LoginResult> login({
    required String email,
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {
        'email': normalizeEmail(email),
        'phone': normalizePhone(phone),
        'otp': otp.trim(),
      },
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final loginResponse = LoginResponse.fromJson(response.data!);
        return LoginResult.success(loginResponse);
      } catch (e) {
        return LoginResult.failure('Invalid response format');
      }
    }

    return LoginResult.failure(response.error?.message ?? 'Login failed');
  }

  /// Get current authenticated user
  Future<AccountResult> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.me);

    if (response.success && response.data != null) {
      try {
        final account = Account.fromJson(response.data!);
        return AccountResult.success(account);
      } catch (e) {
        return AccountResult.failure('Invalid account data');
      }
    }

    return AccountResult.failure(
      response.error?.message ?? 'Failed to get account',
    );
  }

  /// Verify OTP without logging in (for verification flows)
  Future<OtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      body: {'phone': normalizePhone(phone), 'otp': otp.trim()},
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      return OtpResponse.fromJson(response.data!);
    }

    return OtpResponse(
      success: false,
      message: response.error?.message ?? 'OTP verification failed',
    );
  }

  /// Update user profile (Name & Phone)
  Future<AccountResult> updateProfile({
    required String name,
    required String phone,
    String? avatar,
  }) async {
    final body = {'name': name.trim(), 'phone': normalizePhone(phone)};

    if (avatar != null) {
      body['avatar'] = avatar;
    }

    final response = await _apiClient.put(
      ApiEndpoints.updateProfile,
      body: body,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final account = Account.fromJson(
          response.data!['data'] ?? response.data!,
        );
        return AccountResult.success(account);
      } catch (e) {
        return AccountResult.failure('Invalid account data');
      }
    }

    return AccountResult.failure(
      response.error?.message ?? 'Failed to update profile',
    );
  }
}

/// Result wrapper for login operation
class LoginResult {
  final bool success;
  final LoginResponse? data;
  final String? errorMessage;

  LoginResult._({required this.success, this.data, this.errorMessage});

  factory LoginResult.success(LoginResponse data) {
    return LoginResult._(success: true, data: data);
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(success: false, errorMessage: message);
  }
}

/// Result wrapper for account fetch operation
class AccountResult {
  final bool success;
  final Account? data;
  final String? errorMessage;

  AccountResult._({required this.success, this.data, this.errorMessage});

  factory AccountResult.success(Account data) {
    return AccountResult._(success: true, data: data);
  }

  factory AccountResult.failure(String message) {
    return AccountResult._(success: false, errorMessage: message);
  }
}
