import 'package:flutter/foundation.dart';

/// Purpose: Environment configuration for different build modes
/// Context: Used throughout the app for API base URLs and feature flags

class Env {
  // ================================
  // API BASE URLs
  // ================================

  /// Android Emulator (maps host machine localhost)
  static const String _androidEmulatorBaseUrl =
      'http://10.0.2.2:3000/api';

  /// Flutter Web (Edge / Chrome)
  static const String _webBaseUrl =
      'http://127.0.0.1:3000/api';

  /// Production API
  static const String _prodBaseUrl =
      'https://api.travellers-triibe.com/api';

  // ================================
  // ENVIRONMENT MODE
  // ================================

  /// True when app is built in release mode
  static const bool isProduction =
      bool.fromEnvironment('dart.vm.product');

  /// Select correct API base URL
  static String get baseUrl {
    if (isProduction) {
      return _prodBaseUrl;
    }

    if (kIsWeb) {
      return _webBaseUrl;
    }

    return _androidEmulatorBaseUrl;
  }

  // ================================
  // APP CONFIGURATION
  // ================================

  /// QR Code expiry duration (minutes)
  static const int qrExpiryMinutes = 5;

  /// Cache TTL (minutes)
  static const int cacheTtlMinutes = 15;

  // ================================
  // PAYMENT CONFIGURATION
  // ================================

  /// Razorpay Key
  /// Use --dart-define=RAZORPAY_KEY=xxxx in production
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_test_RxUlvgLoEpLdKy',
  );
}
