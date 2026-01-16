/// File: env.dart
/// Purpose: Environment configuration for different build modes
/// Context: Used throughout the app for API base URLs and feature flags
library;

class Env {
  // ============================================
  // UPDATED: Both dev and prod now use Railway
  // This fixes the login issue by connecting to your live backend
  // ============================================
  static const String _devBaseUrl = 'https://travellers-triibe.up.railway.app/api';
  static const String _prodBaseUrl = 'https://travellers-triibe.up.railway.app/api';

  /// Current environment mode
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// API Base URL based on environment
  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;

  /// QR Code expiry duration in minutes
  static const int qrExpiryMinutes = 5;

  /// Cache TTL in minutes
  static const int cacheTtlMinutes = 15;

  /// Razorpay Key - Using live key for production
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_live_S2xrN47XnQ6fWv',
  );
}