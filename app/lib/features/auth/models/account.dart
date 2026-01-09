/// Account model for authentication
library;

import '../../../core/config/constants.dart';

/// User account model representing authenticated user
class Account {
  final String accountId;
  final String email;
  final String phone;
  final String name;
  final String? profilePicture; // Added
  final bool phoneVerified;
  final bool emailVerified;
  final List<UserRole> roles;
  final AccountStatus status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  Account({
    required this.accountId,
    required this.email,
    required this.phone,
    required this.name,
    this.profilePicture, // Added
    this.phoneVerified = false,
    this.emailVerified = false,
    required this.roles,
    required this.status,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Create from JSON response
  factory Account.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['roles'] as List<dynamic>? ?? ['USER'];
    return Account(
      accountId: json['accountId'] ?? json['account_id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      profilePicture:
          json['profilePicture'] ??
          json['avatar'] ??
          json['profile_picture'], // Added mapping
      phoneVerified: json['phone_verified'] ?? false,
      emailVerified: json['email_verified'] ?? false,
      roles: rolesJson.map((r) => UserRole.fromString(r.toString())).toList(),
      status: AccountStatus.fromString(json['status'] ?? 'ACTIVE'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'email': email,
      'phone': phone,
      'name': name,
      'avatar': profilePicture, // Added
      'phone_verified': phoneVerified,
      'email_verified': emailVerified,
      'roles': roles.map((r) => r.name.toUpperCase()).toList(),
      'status': status.name.toUpperCase(),
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// Check if account has a specific role
  bool hasRole(UserRole role) => roles.contains(role);

  /// Convenience getters for role checks
  bool get isUser => hasRole(UserRole.user);
  bool get isPartner => hasRole(UserRole.partner);
  bool get isAdmin => hasRole(UserRole.admin);

  /// Check if account is active
  bool get isActive => status == AccountStatus.active;

  /// Create a copy with updated fields
  Account copyWith({
    String? accountId,
    String? email,
    String? phone,
    String? name,
    String? profilePicture, // Added
    bool? phoneVerified,
    bool? emailVerified,
    List<UserRole>? roles,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return Account(
      accountId: accountId ?? this.accountId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture, // Added
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'Account(id: $accountId, email: $email, roles: $roles)';
  }
}

/// Login response model
class LoginResponse {
  final String token;
  final String? refreshToken;
  final Account account;

  LoginResponse({
    required this.token,
    this.refreshToken,
    required this.account,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      refreshToken: json['refresh_token'],
      account: Account.fromJson(json['account'] ?? {}),
    );
  }
}

/// OTP request response
class OtpResponse {
  final bool success;
  final String message;
  final int? expiresIn; // seconds

  OtpResponse({required this.success, required this.message, this.expiresIn});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      expiresIn: json['expires_in'],
    );
  }
}
