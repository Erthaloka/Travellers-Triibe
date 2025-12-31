/// File: env.dart
/// Purpose: Environment configuration for different build modes
/// Context: Used throughout the app for API base URLs and feature flags

class Env {
  static const String _devBaseUrl = 'http://localhost:3000/api';
  static const String _prodBaseUrl = 'https://api.travellers-triibe.com/api';

  /// Current environment mode
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// API Base URL based on environment
  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;

  /// QR Code expiry duration in minutes
  static const int qrExpiryMinutes = 5;

  /// Cache TTL in minutes
  static const int cacheTtlMinutes = 15;

  /// Razorpay Key (set from environment)
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_test_RxUlvgLoEpLdKy',
  );
}
