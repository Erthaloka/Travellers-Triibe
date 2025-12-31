/// Bills service for bill/QR code API calls
library;

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Bills service - handles all bill-related API calls
class BillsService {
  final ApiClient _apiClient;

  BillsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Partner: Create a new bill and get QR token
  Future<CreateBillResult> createBill({
    required double amount,
    required double discountRate,
    String? description,
    int expiryMinutes = 5,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.billCreate,
      body: {
        'amount': amount,
        'discountRate': discountRate,
        if (description != null && description.isNotEmpty) 'description': description,
        'expiryMinutes': expiryMinutes,
      },
    );

    if (response.success && response.data != null) {
      try {
        final data = response.data!['data'] ?? response.data!;
        return CreateBillResult.success(BillData.fromJson(data));
      } catch (e) {
        return CreateBillResult.failure('Invalid response format');
      }
    }

    return CreateBillResult.failure(
      response.error?.message ?? 'Failed to create bill',
    );
  }

  /// Partner: Get active bills
  Future<ActiveBillsResult> getActiveBills() async {
    final response = await _apiClient.get(ApiEndpoints.billActive);

    if (response.success && response.data != null) {
      try {
        final data = response.data!['data'] ?? response.data!;
        final bills = (data['bills'] as List)
            .map((b) => ActiveBill.fromJson(b))
            .toList();
        return ActiveBillsResult.success(bills);
      } catch (e) {
        return ActiveBillsResult.failure('Invalid response format');
      }
    }

    return ActiveBillsResult.failure(
      response.error?.message ?? 'Failed to fetch bills',
    );
  }

  /// Partner: Cancel a bill
  Future<CancelBillResult> cancelBill(String billId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.billCancel(billId),
    );

    if (response.success) {
      return CancelBillResult.success();
    }

    return CancelBillResult.failure(
      response.error?.message ?? 'Failed to cancel bill',
    );
  }

  /// User: Validate a scanned QR code
  Future<ValidateBillResult> validateQr(String qrToken) async {
    final response = await _apiClient.post(
      ApiEndpoints.billValidate,
      body: {'qrToken': qrToken},
    );

    if (response.success && response.data != null) {
      try {
        final data = response.data!['data'] ?? response.data!;
        return ValidateBillResult.success(ValidatedBill.fromJson(data));
      } catch (e) {
        return ValidateBillResult.failure('Invalid response format');
      }
    }

    return ValidateBillResult.failure(
      response.error?.message ?? 'Invalid or expired QR code',
    );
  }

  /// User: Initiate payment for a bill
  Future<InitiatePaymentResult> initiatePayment(String billId) async {
    final response = await _apiClient.post(
      ApiEndpoints.billPay,
      body: {'billId': billId},
    );

    if (response.success && response.data != null) {
      try {
        final data = response.data!['data'] ?? response.data!;
        return InitiatePaymentResult.success(PaymentData.fromJson(data));
      } catch (e) {
        return InitiatePaymentResult.failure('Invalid response format');
      }
    }

    return InitiatePaymentResult.failure(
      response.error?.message ?? 'Failed to initiate payment',
    );
  }
}

// ============== Data Models ==============

/// Created bill data
class BillData {
  final String billId;
  final String qrToken;
  final BillAmounts amounts;
  final DateTime expiresAt;
  final int expiryMinutes;
  final String businessName;
  final String category;

  BillData({
    required this.billId,
    required this.qrToken,
    required this.amounts,
    required this.expiresAt,
    required this.expiryMinutes,
    required this.businessName,
    required this.category,
  });

  factory BillData.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'] as Map<String, dynamic>? ?? {};
    final amounts = json['amounts'] as Map<String, dynamic>? ?? {};
    return BillData(
      billId: json['billId'] ?? '',
      qrToken: json['qrToken'] ?? '',
      amounts: BillAmounts.fromJson(amounts),
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      expiryMinutes: json['expiryMinutes'] ?? 5,
      businessName: partner['businessName'] ?? '',
      category: partner['category'] ?? '',
    );
  }
}

/// Active bill summary
class ActiveBill {
  final String billId;
  final double amount;
  final int amountInPaise;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  ActiveBill({
    required this.billId,
    required this.amount,
    required this.amountInPaise,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory ActiveBill.fromJson(Map<String, dynamic> json) {
    return ActiveBill(
      billId: json['billId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      amountInPaise: json['amountInPaise'] ?? 0,
      status: json['status'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Validated bill data (from QR scan)
class ValidatedBill {
  final String billId;
  final MerchantInfo merchant;
  final BillAmounts amounts;
  final String? description;
  final DateTime expiresAt;

  ValidatedBill({
    required this.billId,
    required this.merchant,
    required this.amounts,
    this.description,
    required this.expiresAt,
  });

  factory ValidatedBill.fromJson(Map<String, dynamic> json) {
    return ValidatedBill(
      billId: json['billId'] ?? '',
      merchant: MerchantInfo.fromJson(json['merchant'] ?? {}),
      amounts: BillAmounts.fromJson(json['amounts'] ?? {}),
      description: json['description'],
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Merchant information
class MerchantInfo {
  final String id;
  final String businessName;
  final String category;
  final bool isVerified;

  MerchantInfo({
    required this.id,
    required this.businessName,
    required this.category,
    required this.isVerified,
  });

  factory MerchantInfo.fromJson(Map<String, dynamic> json) {
    return MerchantInfo(
      id: json['id'] ?? '',
      businessName: json['businessName'] ?? 'Unknown Merchant',
      category: json['category'] ?? 'OTHER',
      isVerified: json['isVerified'] ?? false,
    );
  }
}

/// Bill amounts breakdown
class BillAmounts {
  final double original;
  final int originalInPaise;
  final double discountPercent;
  final double discountAmount;
  final int discountAmountInPaise;
  final double final_;
  final int finalInPaise;

  BillAmounts({
    required this.original,
    required this.originalInPaise,
    required this.discountPercent,
    required this.discountAmount,
    required this.discountAmountInPaise,
    required this.final_,
    required this.finalInPaise,
  });

  factory BillAmounts.fromJson(Map<String, dynamic> json) {
    return BillAmounts(
      original: (json['original'] as num?)?.toDouble() ?? 0.0,
      originalInPaise: json['originalInPaise'] ?? 0,
      discountPercent: (json['discountPercent'] ?? json['discountRate'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmountInPaise: json['discountAmountInPaise'] ?? 0,
      final_: (json['final'] as num?)?.toDouble() ?? 0.0,
      finalInPaise: json['finalInPaise'] ?? 0,
    );
  }
}

/// Payment initiation data
class PaymentData {
  final String orderId;
  final OrderInfo order;
  final RazorpayInfo razorpay;
  final MerchantBasicInfo merchant;

  PaymentData({
    required this.orderId,
    required this.order,
    required this.razorpay,
    required this.merchant,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      orderId: json['orderId'] ?? '',
      order: OrderInfo.fromJson(json['order'] ?? {}),
      razorpay: RazorpayInfo.fromJson(json['razorpay'] ?? {}),
      merchant: MerchantBasicInfo.fromJson(json['merchant'] ?? {}),
    );
  }
}

/// Order information
class OrderInfo {
  final String id;
  final double originalAmount;
  final double discountRate;
  final double discountAmount;
  final double finalAmount;

  OrderInfo({
    required this.id,
    required this.originalAmount,
    required this.discountRate,
    required this.discountAmount,
    required this.finalAmount,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'] ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      discountRate: (json['discountRate'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Razorpay order info
class RazorpayInfo {
  final String orderId;
  final int amount;
  final String currency;
  final String key;

  RazorpayInfo({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory RazorpayInfo.fromJson(Map<String, dynamic> json) {
    return RazorpayInfo(
      orderId: json['orderId'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      key: json['key'] ?? '',
    );
  }
}

/// Merchant basic info
class MerchantBasicInfo {
  final String businessName;
  final String category;

  MerchantBasicInfo({
    required this.businessName,
    required this.category,
  });

  factory MerchantBasicInfo.fromJson(Map<String, dynamic> json) {
    return MerchantBasicInfo(
      businessName: json['businessName'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

// ============== Result Wrappers ==============

class CreateBillResult {
  final bool success;
  final BillData? data;
  final String? errorMessage;

  CreateBillResult._({required this.success, this.data, this.errorMessage});

  factory CreateBillResult.success(BillData data) =>
      CreateBillResult._(success: true, data: data);

  factory CreateBillResult.failure(String message) =>
      CreateBillResult._(success: false, errorMessage: message);
}

class ActiveBillsResult {
  final bool success;
  final List<ActiveBill>? data;
  final String? errorMessage;

  ActiveBillsResult._({required this.success, this.data, this.errorMessage});

  factory ActiveBillsResult.success(List<ActiveBill> data) =>
      ActiveBillsResult._(success: true, data: data);

  factory ActiveBillsResult.failure(String message) =>
      ActiveBillsResult._(success: false, errorMessage: message);
}

class CancelBillResult {
  final bool success;
  final String? errorMessage;

  CancelBillResult._({required this.success, this.errorMessage});

  factory CancelBillResult.success() =>
      CancelBillResult._(success: true);

  factory CancelBillResult.failure(String message) =>
      CancelBillResult._(success: false, errorMessage: message);
}

class ValidateBillResult {
  final bool success;
  final ValidatedBill? data;
  final String? errorMessage;

  ValidateBillResult._({required this.success, this.data, this.errorMessage});

  factory ValidateBillResult.success(ValidatedBill data) =>
      ValidateBillResult._(success: true, data: data);

  factory ValidateBillResult.failure(String message) =>
      ValidateBillResult._(success: false, errorMessage: message);
}

class InitiatePaymentResult {
  final bool success;
  final PaymentData? data;
  final String? errorMessage;

  InitiatePaymentResult._({required this.success, this.data, this.errorMessage});

  factory InitiatePaymentResult.success(PaymentData data) =>
      InitiatePaymentResult._(success: true, data: data);

  factory InitiatePaymentResult.failure(String message) =>
      InitiatePaymentResult._(success: false, errorMessage: message);
}
