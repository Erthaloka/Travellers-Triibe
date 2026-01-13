/// File: validators.dart
/// Purpose: Input validation utilities
/// Context: Used in forms and API requests for data validation
library;

/// Validation result with error message
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Input validators
class Validators {
  /// Validate email address
  static ValidationResult email(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Email is required');
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return const ValidationResult.invalid('Enter a valid email address');
    }

    return const ValidationResult.valid();
  }

  /// Validate Indian phone number (E.164 format)
  static ValidationResult phone(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Phone number is required');
    }

    // Remove non-digits except +
    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Must be 10 digits or 13 with +91
    if (cleaned.startsWith('+91')) {
      if (cleaned.length != 13) {
        return const ValidationResult.invalid('Enter a valid 10-digit phone number');
      }
    } else if (cleaned.startsWith('91')) {
      if (cleaned.length != 12) {
        return const ValidationResult.invalid('Enter a valid 10-digit phone number');
      }
    } else {
      if (cleaned.length != 10) {
        return const ValidationResult.invalid('Enter a valid 10-digit phone number');
      }
    }

    // Check if starts with valid digit (6-9 for Indian numbers)
    String lastTenDigits = cleaned.substring(cleaned.length - 10);
    if (!RegExp(r'^[6-9]').hasMatch(lastTenDigits)) {
      return const ValidationResult.invalid('Enter a valid Indian phone number');
    }

    return const ValidationResult.valid();
  }

  /// Validate OTP (6 digits)
  static ValidationResult otp(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('OTP is required');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return const ValidationResult.invalid('Enter a valid 6-digit OTP');
    }

    return const ValidationResult.valid();
  }

  /// Validate GSTIN (15 characters)
  static ValidationResult gstin(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('GSTIN is required');
    }

    String cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (cleaned.length != 15) {
      return const ValidationResult.invalid('GSTIN must be 15 characters');
    }

    // GSTIN format: 2-digit state code + 10-char PAN + 1-digit entity + Z + 1-digit checksum
    // Example: 29ABCDE1234F1Z5
    final gstinRegex = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    );

    if (!gstinRegex.hasMatch(cleaned)) {
      return const ValidationResult.invalid('Enter a valid GSTIN');
    }

    // Validate state code (01-37 are valid)
    int stateCode = int.tryParse(cleaned.substring(0, 2)) ?? 0;
    if (stateCode < 1 || stateCode > 37) {
      return const ValidationResult.invalid('Invalid state code in GSTIN');
    }

    return const ValidationResult.valid();
  }

  /// Validate business name
  static ValidationResult businessName(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Business name is required');
    }

    if (value.trim().length < 3) {
      return const ValidationResult.invalid('Business name must be at least 3 characters');
    }

    if (value.trim().length > 100) {
      return const ValidationResult.invalid('Business name is too long');
    }

    return const ValidationResult.valid();
  }

  /// Validate amount (positive number)
  static ValidationResult amount(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Amount is required');
    }

    double? amount = double.tryParse(value.replaceAll(',', ''));

    if (amount == null) {
      return const ValidationResult.invalid('Enter a valid amount');
    }

    if (amount <= 0) {
      return const ValidationResult.invalid('Amount must be greater than 0');
    }

    if (amount > 10000000) {
      return const ValidationResult.invalid('Amount exceeds maximum limit');
    }

    return const ValidationResult.valid();
  }

  /// Validate pincode (6 digits for India)
  static ValidationResult pincode(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Pincode is required');
    }

    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value)) {
      return const ValidationResult.invalid('Enter a valid 6-digit pincode');
    }

    return const ValidationResult.valid();
  }

  /// Validate required field
  static ValidationResult required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }
    return const ValidationResult.valid();
  }

  /// Validate minimum length
  static ValidationResult minLength(String? value, int minLen, [String fieldName = 'Field']) {
    if (value == null || value.trim().length < minLen) {
      return ValidationResult.invalid('$fieldName must be at least $minLen characters');
    }
    return const ValidationResult.valid();
  }

  /// Validate maximum length
  static ValidationResult maxLength(String? value, int maxLen, [String fieldName = 'Field']) {
    if (value != null && value.trim().length > maxLen) {
      return ValidationResult.invalid('$fieldName must not exceed $maxLen characters');
    }
    return const ValidationResult.valid();
  }
}

/// Form field validator wrapper for Flutter forms
class FormValidators {
  /// Email validator for TextFormField
  static String? email(String? value) {
    final result = Validators.email(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Phone validator for TextFormField
  static String? phone(String? value) {
    final result = Validators.phone(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// OTP validator for TextFormField
  static String? otp(String? value) {
    final result = Validators.otp(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// GSTIN validator for TextFormField
  static String? gstin(String? value) {
    final result = Validators.gstin(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Business name validator for TextFormField
  static String? businessName(String? value) {
    final result = Validators.businessName(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Amount validator for TextFormField
  static String? amount(String? value) {
    final result = Validators.amount(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Pincode validator for TextFormField
  static String? pincode(String? value) {
    final result = Validators.pincode(value);
    return result.isValid ? null : result.errorMessage;
  }

  /// Required field validator for TextFormField
  static String? Function(String?) required([String fieldName = 'This field']) {
    return (value) {
      final result = Validators.required(value, fieldName);
      return result.isValid ? null : result.errorMessage;
    };
  }
}
