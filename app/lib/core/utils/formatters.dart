/// File: formatters.dart
/// Purpose: Currency, date, and number formatting utilities
/// Context: Used throughout the app for consistent display formatting
library;

import 'package:intl/intl.dart';

/// Currency formatter for Indian Rupees
class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9', // ₹ symbol
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  /// Format amount as currency (e.g., ₹1,234.56)
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format amount without decimals (e.g., ₹1,235)
  static String formatWhole(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    ).format(amount.round());
  }

  /// Format compact (e.g., ₹1.2K, ₹12L)
  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  /// Format as plain number with commas (no currency symbol)
  static String formatNumber(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }

  /// Format percentage (e.g., 6%)
  static String formatPercent(double percent) {
    return '${percent.toStringAsFixed(0)}%';
  }

  /// Format discount display (e.g., -₹32.40)
  static String formatDiscount(double amount) {
    return '-${format(amount)}';
  }

  /// Format savings with highlight (e.g., You saved ₹32.40)
  static String formatSavings(double amount) {
    return 'You saved ${format(amount)}';
  }
}

/// Date and time formatters
class DateTimeFormatter {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');

  /// Format as date only (e.g., 24 Dec 2024)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format as time only (e.g., 10:30 AM)
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format as date and time (e.g., 24 Dec 2024, 10:30 AM)
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format as short date (e.g., 24/12/24)
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format as month and year (e.g., December 2024)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format as day and month (e.g., 24 Dec)
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// Format as relative time (e.g., 2 hours ago, Yesterday)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  /// Parse ISO 8601 date string
  static DateTime? parseIso(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Format for API (ISO 8601)
  static String toIso(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}

/// Phone number formatter
class PhoneFormatter {
  /// Format phone for display (e.g., +91 98765 43210)
  static String format(String phone) {
    if (phone.isEmpty) return '';

    // Remove non-digits except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Indian phone number formatting
    if (cleaned.startsWith('+91') && cleaned.length == 13) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
    }

    return cleaned;
  }

  /// Mask phone number (e.g., +91****3210)
  static String mask(String phone) {
    if (phone.isEmpty) return '';

    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.length >= 10) {
      final lastFour = cleaned.substring(cleaned.length - 4);
      final prefix = cleaned.length > 10 ? cleaned.substring(0, 3) : '';
      return '$prefix****$lastFour';
    }

    return cleaned;
  }
}

/// Order ID formatter
class OrderIdFormatter {
  /// Format order ID for display (e.g., ORD-001)
  static String format(String orderId) {
    if (orderId.isEmpty) return '';

    // If already formatted, return as is
    if (orderId.toUpperCase().startsWith('ORD-')) {
      return orderId.toUpperCase();
    }

    // Otherwise, add prefix
    return 'ORD-${orderId.toUpperCase()}';
  }

  /// Shorten order ID (e.g., ...ABC123)
  static String shorten(String orderId, {int length = 8}) {
    if (orderId.length <= length) return orderId.toUpperCase();
    return '...${orderId.substring(orderId.length - length).toUpperCase()}';
  }
}
