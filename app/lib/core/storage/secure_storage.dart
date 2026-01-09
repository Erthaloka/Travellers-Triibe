/// File: secure_storage.dart
/// Purpose: Secure token and sensitive data storage
/// Context: Used for JWT tokens and user session data

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys for secure storage
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String lastActiveRole = 'last_active_role';
  static const String accountId = 'account_id';
}

/// Secure storage wrapper
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // ============== AUTH TOKEN ==============

  /// Get stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: StorageKeys.authToken);
  }

  /// Store JWT token
  Future<void> setToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  /// Delete JWT token
  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  /// Check if token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ============== REFRESH TOKEN ==============

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  /// Store refresh token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  // ============== LAST ACTIVE ROLE ==============

  /// Get last active role
  Future<String?> getLastActiveRole() async {
    return await _storage.read(key: StorageKeys.lastActiveRole);
  }

  /// Store last active role
  Future<void> setLastActiveRole(String role) async {
    await _storage.write(key: StorageKeys.lastActiveRole, value: role);
  }

  /// Delete last active role
  Future<void> deleteLastActiveRole() async {
    await _storage.delete(key: StorageKeys.lastActiveRole);
  }

  // ============== ACCOUNT ID ==============

  /// Get stored account ID
  Future<String?> getAccountId() async {
    return await _storage.read(key: StorageKeys.accountId);
  }

  /// Store account ID
  Future<void> setAccountId(String accountId) async {
    await _storage.write(key: StorageKeys.accountId, value: accountId);
  }

  /// Delete account ID
  Future<void> deleteAccountId() async {
    await _storage.delete(key: StorageKeys.accountId);
  }

  // ============== SESSION MANAGEMENT ==============

  /// Clear all auth data (logout)
  Future<void> clearAll() async {
    await Future.wait([
      deleteToken(),
      deleteRefreshToken(),
      deleteLastActiveRole(),
      deleteAccountId(),
    ]);
  }

  /// Store all session data at once
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    required String accountId,
    required String role,
  }) async {
    await Future.wait([
      setToken(token),
      if (refreshToken != null) setRefreshToken(refreshToken),
      setAccountId(accountId),
      setLastActiveRole(role),
    ]);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await hasToken();
  }
}
