/// File: auth_provider.dart
/// Purpose: Authentication state management
/// Context: Manages user session, roles, and authentication status

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';
import '../storage/secure_storage.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../features/auth/auth_service.dart';
import '../../features/auth/models/account.dart';

/// Authentication state
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Authentication provider
class AuthProvider extends ChangeNotifier {
  final SecureStorage _secureStorage;
  final ApiClient _apiClient;
  GoogleSignIn? _googleSignIn;

  AuthState _state = AuthState.initial;
  Account? _account;
  UserRole _activeRole = UserRole.user;
  String? _errorMessage;
  String? _pendingSignupRole;

  AuthProvider({
    required SecureStorage secureStorage,
    required ApiClient apiClient,
  }) : _secureStorage = secureStorage,
       _apiClient = apiClient;

  /// Get or initialize GoogleSignIn lazily
  GoogleSignIn _getGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);
    return _googleSignIn!;
  }

  // Getters
  AuthState get state => _state;
  Account? get account => _account;
  UserRole get activeRole => _activeRole;
  String? get errorMessage => _errorMessage;
  String? get pendingSignupRole => _pendingSignupRole;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _account != null;
  bool get isLoading => _state == AuthState.loading;

  /// Set pending signup role (called from profile selection)
  void setSignupRole(String role) {
    _pendingSignupRole = role;
    if (kDebugMode) {
      print('✅ AuthProvider: Signup role set to: $_pendingSignupRole');
    }
  }

  /// Initialize auth state from storage
  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final hasToken = await _secureStorage.hasToken();

      if (hasToken) {
        // Validate token with backend
        final response = await _apiClient.get(ApiEndpoints.me);

        if (response.success && response.data != null) {
          // Extract user data from response wrapper
          final userData = response.data!['data'] ?? response.data!;
          try {
            _account = Account.fromJson(userData);
          } catch (_) {
            // If parsing fails, try original (just in case logic changes)
            _account = Account.fromJson(response.data!);
          }

          // Restore last active role
          final lastRole = await _secureStorage.getLastActiveRole();
          if (lastRole != null) {
            final role = UserRole.fromString(lastRole);
            if (_account!.hasRole(role)) {
              _activeRole = role;
            }
          } else if (_account!.roles.isNotEmpty) {
            _activeRole = _account!.roles.first;
          }

          // Cache the fresh account data
          await _secureStorage.setAccountData(jsonEncode(response.data!));

          _state = AuthState.authenticated;
        } else if (response.statusCode == 401) {
          // Token invalid, clear storage
          await _secureStorage.clearAll();
          _state = AuthState.unauthenticated;
        } else {
          // Network error or server error - Try to load from cache
          final cachedDataStr = await _secureStorage.getAccountData();
          if (cachedDataStr != null) {
            try {
              final cachedData = jsonDecode(cachedDataStr);
              _account = Account.fromJson(cachedData);
              // Restore role logic (simplified)
              final lastRole = await _secureStorage.getLastActiveRole();
              if (lastRole != null) {
                _activeRole = UserRole.fromString(lastRole);
              } else if (_account!.roles.isNotEmpty) {
                _activeRole = _account!.roles.first;
              }
              _state = AuthState.authenticated;
            } catch (_) {
              // Cache corrupt
              _state = AuthState.error;
              _errorMessage =
                  'Unable to connect. Please check your internet connection.';
            }
          } else {
            // No cache available
            _state = AuthState.error;
            _errorMessage =
                'Unable to connect. Please check your internet connection.';
          }
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      // Unexpected error - Try to fallback to cache
      try {
        final cachedDataStr = await _secureStorage.getAccountData();
        if (cachedDataStr != null) {
          final cachedData = jsonDecode(cachedDataStr);
          _account = Account.fromJson(cachedData);
          final lastRole = await _secureStorage.getLastActiveRole();
          if (lastRole != null) {
            _activeRole = UserRole.fromString(lastRole);
          } else if (_account!.roles.isNotEmpty) {
            _activeRole = _account!.roles.first;
          }
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } catch (_) {
        _state = AuthState.unauthenticated;
      }
      _errorMessage = null;
    }

    notifyListeners();
  }

  /// Login with email and password
  Future<bool> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data!;
        final token = data['token'] as String?;
        final accountData = data['account'] as Map<String, dynamic>?;

        if (token != null && accountData != null) {
          _account = Account.fromJson(accountData);

          if (_account!.roles.isNotEmpty) {
            _activeRole = _account!.roles.first;
          }

          await _secureStorage.saveSession(
            token: token,
            accountId: _account!.accountId,
            role: _activeRole.name.toUpperCase(),
          );

          _state = AuthState.authenticated;
          notifyListeners();
          return true;
        }
      }

      _state = AuthState.error;
      _errorMessage = response.error?.message ?? 'Invalid email or password';
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle({bool isSignup = false}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleSignIn = _getGoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      // Get Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        _state = AuthState.error;
        _errorMessage = 'Failed to get Google authentication token';
        notifyListeners();
        return false;
      }

      if (kDebugMode) {
        print(
          '🔵 Google Sign-In: Sending role = ${_pendingSignupRole?.toLowerCase() ?? 'user'}',
        );
      }

      // Send to backend for verification
      final response = await _apiClient.post(
        ApiEndpoints.firebaseAuth,
        body: {
          'idToken': idToken ?? accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'User',
          'role':
              _pendingSignupRole?.toLowerCase() ??
              'user', // ✅ CRITICAL: Send role
        },
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data!;
        final token = data['token'] as String?;
        final accountData = data['account'] as Map<String, dynamic>?;

        if (token != null && accountData != null) {
          _account = Account.fromJson(accountData);

          // Set active role based on signup selection
          final signupRole = UserRole.fromString(_pendingSignupRole ?? 'user');
          if (_account!.hasRole(signupRole)) {
            _activeRole = signupRole;
          } else if (_account!.roles.isNotEmpty) {
            _activeRole = _account!.roles.first;
          }

          await _secureStorage.saveSession(
            token: token,
            accountId: _account!.accountId,
            role: _activeRole.name.toUpperCase(),
          );

          _pendingSignupRole = null; // Clear after use
          _state = AuthState.authenticated;
          notifyListeners();
          return true;
        }
      }

      _state = AuthState.error;
      _errorMessage = response.error?.message ?? 'Google sign-in failed';
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Google sign-in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Signup with email and password
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print(
          '🔵 Signup: Sending role = ${_pendingSignupRole?.toLowerCase() ?? 'user'}',
        );
        print(
          '🔵 Signup payload: name=$name, email=$email, phone=$phone, role=${_pendingSignupRole?.toLowerCase() ?? 'user'}',
        );
      }

      final response = await _apiClient.post(
        ApiEndpoints.signup,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': _pendingSignupRole?.toLowerCase() ?? 'user',
        },
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data!;
        final token = data['token'] as String?;
        final accountData = data['account'] as Map<String, dynamic>?;

        if (token != null && accountData != null) {
          _account = Account.fromJson(accountData);

          if (kDebugMode) {
            print('✅ Signup successful! User roles: ${_account!.roles}');
          }

          // Set active role based on signup selection
          final signupRole = UserRole.fromString(_pendingSignupRole ?? 'user');
          if (_account!.hasRole(signupRole)) {
            _activeRole = signupRole;
          } else if (_account!.roles.isNotEmpty) {
            _activeRole = _account!.roles.first;
          }

          await _secureStorage.saveSession(
            token: token,
            accountId: _account!.accountId,
            role: _activeRole.name.toUpperCase(),
          );

          _pendingSignupRole = null; // Clear after successful signup
          _state = AuthState.authenticated;
          notifyListeners();
          return true;
        }
      }

      _state = AuthState.error;
      _errorMessage = response.error?.message ?? 'Signup failed';
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Signup failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Switch active role (no re-login required)
  Future<void> switchRole(UserRole role) async {
    if (_account == null) return;
    if (!_account!.hasRole(role)) return;

    _activeRole = role;
    await _secureStorage.setLastActiveRole(role.name.toUpperCase());
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    // Sign out from Google if signed in
    try {
      final googleSignIn = _getGoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}

    await _secureStorage.clearAll();

    _account = null;
    _activeRole = UserRole.user;
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    _pendingSignupRole = null;
    notifyListeners();
  }

  /// Add role to current account
  void addRole(UserRole role) {
    if (_account != null && !_account!.roles.contains(role)) {
      final updatedRoles = [..._account!.roles, role];
      _account = _account!.copyWith(roles: updatedRoles);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user has specific role
  bool hasRole(UserRole role) {
    return _account?.hasRole(role) ?? false;
  }

  /// Get available roles for switching
  List<UserRole> get availableRoles {
    return _account?.roles ?? [];
  }

  /// Check if profile is complete (has phone number)
  bool get isProfileComplete {
    return _account?.phone != null && _account!.phone.isNotEmpty;
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? avatar,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService(apiClient: _apiClient);
      final result = await authService.updateProfile(
        name: name,
        phone: phone,
        avatar: avatar,
      );

      if (result.success && result.data != null) {
        _account = result.data;
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      }

      _state = AuthState.error;
      _errorMessage = result.errorMessage ?? 'Failed to update profile';
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Update failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Save profile draft
  Future<void> saveProfileDraft(String name, String phone) async {
    await _secureStorage.saveProfileDraft(name, phone);
  }

  /// Get profile draft
  Future<Map<String, String?>> getProfileDraft() async {
    return await _secureStorage.getProfileDraft();
  }

  /// Clear profile draft
  Future<void> clearProfileDraft() async {
    await _secureStorage.clearProfileDraft();
  }
}
