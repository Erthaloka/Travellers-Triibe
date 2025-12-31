/// File: text_normalizer.dart
/// Purpose: Unicode safety and text normalization
/// Context: Applied at all text entry points to prevent Unicode issues

/// Normalizes user-provided text to prevent Unicode issues.
/// - Removes zero-width characters
/// - Trims whitespace
/// - Sanitizes for safe storage and display
String normalizeText(String? input) {
  if (input == null || input.isEmpty) return '';

  return input
      // Remove zero-width characters (ZWJ, ZWNJ, ZWSP, BOM)
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00AD]'), '')
      // Remove other invisible formatting characters
      .replaceAll(RegExp(r'[\u2060-\u206F]'), '')
      // Normalize multiple spaces to single space
      .replaceAll(RegExp(r'\s+'), ' ')
      // Trim leading and trailing whitespace
      .trim();
}

/// Normalizes phone number to E.164 format
/// Only allows digits and leading +
String normalizePhone(String? input) {
  if (input == null || input.isEmpty) return '';

  // Remove all non-digit characters except leading +
  String normalized = input.replaceAll(RegExp(r'[^\d+]'), '');

  // Ensure only one + at the beginning
  if (normalized.contains('+')) {
    normalized = '+${normalized.replaceAll('+', '')}';
  }

  return normalized;
}

/// Normalizes GSTIN to uppercase ASCII only
/// Removes any non-alphanumeric characters
String normalizeGstin(String? input) {
  if (input == null || input.isEmpty) return '';

  return input
      .toUpperCase()
      // Remove any non-alphanumeric characters
      .replaceAll(RegExp(r'[^A-Z0-9]'), '')
      .trim();
}

/// Normalizes email to lowercase
String normalizeEmail(String? input) {
  if (input == null || input.isEmpty) return '';

  return input.toLowerCase().trim();
}

/// Sanitizes text for display (prevents XSS-like issues)
String sanitizeForDisplay(String? input) {
  if (input == null || input.isEmpty) return '';

  return input
      // Remove script tags
      .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
      // Remove other HTML tags
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();
}

/// Checks if text contains only ASCII characters
bool isAsciiOnly(String input) {
  return input.codeUnits.every((unit) => unit < 128);
}

/// Truncates text to specified length with ellipsis
String truncateText(String? input, int maxLength) {
  if (input == null || input.isEmpty) return '';
  if (input.length <= maxLength) return input;

  return '${input.substring(0, maxLength - 3)}...';
}
