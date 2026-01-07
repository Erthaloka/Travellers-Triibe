/// File: auth_provider.dart
/// Purpose: Authentication state management
/// Context: Manages user session, roles, and authentication status
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';
import '../storage/secure_storage.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// User account model
class Account {
  final String accountId;
  final String email;
  final String phone;
  final String name;
  final List<UserRole> roles;
  final AccountStatus status;
  final int totalSavings;
  final int totalOrders;

  Account({
    required this.accountId,
    required this.email,
    required this.phone,
    required this.name,
    required this.roles,
    required this.status,
    this.totalSavings = 0,
    this.totalOrders = 0,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['roles'] as List<dynamic>? ?? ['USER'];
    return Account(
      accountId: json['id'] ?? json['_id'] ?? json['account_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      roles: rolesJson.map((r) => UserRole.fromString(r.toString())).toList(),
      status: AccountStatus.fromString(json['status'] ?? 'ACTIVE'),
      totalSavings: json['totalSavings'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
    );
  }

  bool hasRole(UserRole role) => roles.contains(role);
  bool get isUser => hasRole(UserRole.user);
  bool get isPartner => hasRole(UserRole.partner);
  bool get isAdmin => hasRole(UserRole.admin);
}

/// Authentication state
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

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
  })  : _secureStorage = secureStorage,
        _apiClient = apiClient;

  /// Get or initialize GoogleSignIn lazily
  GoogleSignIn _getGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    return _googleSignIn!;
  }

  // Getters
  AuthState get state => _state;
  Account? get account => _account;
  UserRole get activeRole => _activeRole;
  String? get errorMessage => _errorMessage;
  String? get pendingSignupRole => _pendingSignupRole;
  bool get isAuthenticated => _state == AuthState.authenticated && _account != null;
  bool get isLoading => _state == AuthState.loading;

  /// Set pending signup role (called from profile selection)
  void setSignupRole(String role) {
    _pendingSignupRole = role;
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
          final data = response.data!['data'] ?? response.data!;
          _account = Account.fromJson(data is Map<String, dynamic> ? data : response.data!);

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

          _state = AuthState.authenticated;
        } else {
          // Token invalid, clear storage
          await _secureStorage.clearAll();
          _state = AuthState.unauthenticated;
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      await _secureStorage.clearAll();
      _state = AuthState.unauthenticated;
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
        body: {
          'email': email,
          'password': password,
        },
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        _state = AuthState.error;
        _errorMessage = 'Failed to get Google authentication token';
        notifyListeners();
        return false;
      }

      // Send to backend for verification
      final response = await _apiClient.post(
        ApiEndpoints.firebaseAuth,
        body: {
          'idToken': idToken ?? accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'User',
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

          _pendingSignupRole = null;
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
      final response = await _apiClient.post(
        ApiEndpoints.signup,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
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

          _pendingSignupRole = null;
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
    notifyListeners();
  }

  /// Add role to current account (used after partner onboarding)
  void addRole(UserRole role) {
    if (_account != null && !_account!.roles.contains(role)) {
      final updatedRoles = [..._account!.roles, role];
      _account = Account(
        accountId: _account!.accountId,
        email: _account!.email,
        phone: _account!.phone,
        name: _account!.name,
        roles: updatedRoles,
        status: _account!.status,
        totalSavings: _account!.totalSavings,
        totalOrders: _account!.totalOrders,
      );
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
}
