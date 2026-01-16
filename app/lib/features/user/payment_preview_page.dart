/// Payment Preview page - shows bill breakdown before payment-payment_preview_page.dart
/// Integrates with Razorpay for actual payment processing
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';
import '../bills/bills_service.dart';

/// Payment preview data passed from QR scan
class PaymentPreviewData {
  final String billId;
  final String qrToken;
  final String merchantId;
  final String merchantName;
  final String merchantCategory;
  final bool isVerified;
  final double billAmount;
  final double discountPercent;
  final double discountAmount;
  final double finalAmount;
  final String? description;
  final DateTime? expiresAt;

  PaymentPreviewData({
    required this.billId,
    required this.qrToken,
    required this.merchantId,
    required this.merchantName,
    required this.merchantCategory,
    required this.isVerified,
    required this.billAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.finalAmount,
    this.description,
    this.expiresAt,
  });

  factory PaymentPreviewData.fromMap(Map<String, dynamic> map) {
    return PaymentPreviewData(
      billId: map['billId'] ?? '',
      qrToken: map['qrToken'] ?? '',
      merchantId: map['merchantId'] ?? '',
      merchantName: map['merchantName'] ?? 'Unknown Merchant',
      merchantCategory: map['merchantCategory'] ?? 'OTHER',
      isVerified: map['isVerified'] ?? false,
      billAmount: (map['billAmount'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'])
          : null,
    );
  }
}

/// Payment preview page - Shows bill and initiates Razorpay payment
class PaymentPreviewPage extends StatefulWidget {
  final PaymentPreviewData data;

  const PaymentPreviewPage({super.key, required this.data});

  @override
  State<PaymentPreviewPage> createState() => _PaymentPreviewPageState();
}

class _PaymentPreviewPageState extends State<PaymentPreviewPage> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _currentOrderId;
  late BillsService _billsService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apiClient = context.read<ApiClient>();
    _billsService = BillsService(apiClient: apiClient);
  }

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  /// STEP 1: Initiate payment - calls backend to create Razorpay order
  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Initiating payment for bill: ${widget.data.billId}');

      // Call backend with timeout
      final result = await _billsService.initiatePayment(widget.data.billId)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection and try again.');
        },
      );

      if (!mounted) return;

      print('📥 Payment initiation response - Success: ${result.success}');

      if (result.success && result.data != null) {
        final paymentData = result.data!;

        print('✅ Order created: ${paymentData.orderId}');
        print('💰 Amount: ${paymentData.razorpay.amount}');
        print('🔑 Razorpay Order ID: ${paymentData.razorpay.orderId}');

        // Store order ID for verification later
        _currentOrderId = paymentData.orderId;

        // STEP 2: Open Razorpay checkout
        _openRazorpayCheckout(paymentData);
      } else {
        throw Exception(result.errorMessage ?? 'Failed to initiate payment');
      }
    } catch (e) {
      print('❌ Payment initiation error: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e.toString())),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _processPayment,
          ),
        ),
      );
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('timed out')) {
      return 'Connection timed out. Please check your internet and try again.';
    } else if (error.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.contains('EXPIRED')) {
      return 'This bill has expired. Please request a new QR code.';
    } else if (error.contains('USED')) {
      return 'This bill has already been paid.';
    }
    return 'Payment failed: ${error.replaceAll('Exception:', '').trim()}';
  }

  /// STEP 2: Open Razorpay payment sheet
  void _openRazorpayCheckout(PaymentData paymentData) {
    print('🚀 Opening Razorpay checkout...');

    final options = {
      'key': paymentData.razorpay.key,
      'amount': paymentData.razorpay.amount,
      'currency': paymentData.razorpay.currency,
      'name': 'Travellers Triibe',
      'description': 'Payment to ${paymentData.merchant.businessName}',
      'order_id': paymentData.razorpay.orderId,
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#6366F1',
      },
    };

    print('📋 Razorpay options: $options');

    try {
      _razorpay.open(options);
      print('✅ Razorpay opened successfully');
    } catch (e) {
      print('❌ Failed to open Razorpay: $e');
      setState(() => _isProcessing = false);
      _showError('Failed to open payment: $e');
    }
  }

  /// STEP 3: Handle successful payment from Razorpay
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success: ${response.paymentId}');
    print('📦 Order ID: ${response.orderId}');
    print('🔐 Signature: ${response.signature}');

    try {
      // STEP 4: Verify payment with backend
      print('🔄 Verifying payment...');

      final verifyResult = await _billsService.verifyPayment(
        orderId: _currentOrderId!,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Verification timed out. Payment may be successful. Please check your order history.');
        },
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      print('📥 Verification response - Success: ${verifyResult.success}');

      if (verifyResult.success) {
        print('✅ Payment verified successfully');

        // STEP 5: Navigate to success page
        context.go(AppRoutes.paymentSuccess, extra: {
          'merchantName': widget.data.merchantName,
          'billAmount': widget.data.billAmount,
          'discountAmount': widget.data.discountAmount,
          'finalAmount': widget.data.finalAmount,
          'orderId': _currentOrderId,
          'paymentId': response.paymentId,
        });
      } else {
        print('❌ Payment verification failed');
        _showError(
          'Payment verification failed. Your payment may be successful. Please contact support with Order ID: $_currentOrderId',
        );
      }
    } catch (e) {
      print('❌ Payment verification error: $e');

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Payment verification error: $e. Your payment may be successful. Order ID: $_currentOrderId');
    }
  }

  /// Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.code} - ${response.message}');

    setState(() => _isProcessing = false);

    _showError(
      response.message ?? 'Payment failed. Please try again.',
    );
  }

  /// Handle external wallet (not supported)
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External Wallet: ${response.walletName}');

    setState(() => _isProcessing = false);

    _showError(
      'External wallet (${response.walletName}) is not supported yet.',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : () => context.go(AppRoutes.userHome),
        ),
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMerchantCard(),
                  const SizedBox(height: 20),
                  _buildAmountBreakdown(),
                  const SizedBox(height: 20),
                  _buildSavingsHighlight(),
                  const SizedBox(height: 16),
                  _buildPaymentInfoBanner(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorCard(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildMerchantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(widget.data.merchantCategory),
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.merchantName,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatCategory(widget.data.merchantCategory),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.data.isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: AppColors.success,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountBreakdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Summary',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.data.description != null &&
              widget.data.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.data.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildAmountRow(
            label: 'Original Bill',
            amount: widget.data.billAmount,
            isHighlighted: false,
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            label:
            'Discount (${widget.data.discountPercent.toStringAsFixed(0)}%)',
            amount: -widget.data.discountAmount,
            isHighlighted: true,
            isDiscount: true,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You Pay',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CurrencyFormatter.format(widget.data.finalAmount),
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow({
    required String label,
    required double amount,
    required bool isHighlighted,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlighted ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        Text(
          isDiscount
              ? '- ${CurrencyFormatter.format(amount.abs())}'
              : CurrencyFormatter.format(amount),
          style: AppTextStyles.bodyLarge.copyWith(
            color: isHighlighted ? AppColors.success : AppColors.textPrimary,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsHighlight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You save',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(widget.data.discountAmount),
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${widget.data.discountPercent.toStringAsFixed(0)}% OFF',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You will be redirected to Razorpay to complete the payment',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    : Text(
                  'Pay ${CurrencyFormatter.format(widget.data.finalAmount)}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => context.go(AppRoutes.userHome),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD':
        return Icons.restaurant;
      case 'STAY':
        return Icons.hotel;
      case 'SERVICE':
        return Icons.miscellaneous_services;
      case 'RETAIL':
        return Icons.shopping_bag;
      default:
        return Icons.store;
    }
  }

  String _formatCategory(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD':
        return 'Food & Dining';
      case 'STAY':
        return 'Hotel & Stay';
      case 'SERVICE':
        return 'Services';
      case 'RETAIL':
        return 'Retail';
      default:
        return 'Other';
    }
  }
}