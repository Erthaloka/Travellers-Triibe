/// File: constants.dart
/// Purpose: App-wide constants and enums
/// Context: Used throughout the app for consistent values

/// User roles in the system
enum UserRole {
  user,
  partner,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.partner:
        return 'Partner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.user,
    );
  }
}

/// Merchant/Order categories
enum OrderCategory {
  food,
  stay,
  service,
  retail;

  String get displayName {
    switch (this) {
      case OrderCategory.food:
        return 'Food';
      case OrderCategory.stay:
        return 'Stay';
      case OrderCategory.service:
        return 'Service';
      case OrderCategory.retail:
        return 'Retail';
    }
  }

  static OrderCategory fromString(String value) {
    return OrderCategory.values.firstWhere(
      (cat) => cat.name.toUpperCase() == value.toUpperCase(),
      orElse: () => OrderCategory.food,
    );
  }
}

/// Payment status
enum PaymentStatus {
  created,
  paid,
  failed;

  String get displayName {
    switch (this) {
      case PaymentStatus.created:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name.toUpperCase() == value.toUpperCase(),
      orElse: () => PaymentStatus.created,
    );
  }
}

/// Settlement modes
enum SettlementMode {
  platform,
  direct;

  String get displayName {
    switch (this) {
      case SettlementMode.platform:
        return 'Platform Managed';
      case SettlementMode.direct:
        return 'Direct Settlement';
    }
  }

  static SettlementMode fromString(String value) {
    return SettlementMode.values.firstWhere(
      (mode) => mode.name.toUpperCase() == value.toUpperCase(),
      orElse: () => SettlementMode.platform,
    );
  }
}

/// Discount slabs available
class DiscountSlabs {
  static const List<int> available = [3, 6, 9];
  static const int defaultSlab = 6;
}

/// GST verification status
enum GstStatus {
  notSubmitted,
  submitted,
  verified,
  rejected;

  String get displayName {
    switch (this) {
      case GstStatus.notSubmitted:
        return 'Not Submitted';
      case GstStatus.submitted:
        return 'Pending Verification';
      case GstStatus.verified:
        return 'Verified';
      case GstStatus.rejected:
        return 'Rejected';
    }
  }

  static GstStatus fromString(String value) {
    final normalized = value.toUpperCase().replaceAll('_', '');
    return GstStatus.values.firstWhere(
      (status) => status.name.toUpperCase() == normalized,
      orElse: () => GstStatus.notSubmitted,
    );
  }
}

/// Account status
enum AccountStatus {
  active,
  blocked;

  static AccountStatus fromString(String value) {
    return AccountStatus.values.firstWhere(
      (status) => status.name.toUpperCase() == value.toUpperCase(),
      orElse: () => AccountStatus.active,
    );
  }
}

/// Merchant status
enum MerchantStatus {
  active,
  suspended;

  static MerchantStatus fromString(String value) {
    return MerchantStatus.values.firstWhere(
      (status) => status.name.toUpperCase() == value.toUpperCase(),
      orElse: () => MerchantStatus.active,
    );
  }
}
