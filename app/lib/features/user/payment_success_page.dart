/// Payment Success page - shows confirmation and savings
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// Payment success data passed from payment processing
class PaymentSuccessData {
  final String merchantName;
  final double billAmount;
  final double discountAmount;
  final double finalAmount;
  final String orderId;

  PaymentSuccessData({
    required this.merchantName,
    required this.billAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.orderId,
  });

  factory PaymentSuccessData.fromMap(Map<String, dynamic> map) {
    return PaymentSuccessData(
      merchantName: map['merchantName'] ?? 'Unknown Merchant',
      billAmount: (map['billAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 0.0,
      orderId: map['orderId'] ?? '',
    );
  }
}

/// Payment success page - confirmation screen
class PaymentSuccessPage extends StatelessWidget {
  final PaymentSuccessData data;

  const PaymentSuccessPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _buildSuccessAnimation(),
              const SizedBox(height: 32),
              _buildSavingsHighlight(),
              const SizedBox(height: 24),
              _buildOrderSummary(),
              const Spacer(),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Successful!',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for paying with Travellers Triibe',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsHighlight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.2),
            AppColors.success.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.savings,
            color: AppColors.success,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'You Saved',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(data.discountAmount),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.success,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'on this transaction',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Merchant', data.merchantName),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Original Bill',
            CurrencyFormatter.format(data.billAmount),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Discount',
            '- ${CurrencyFormatter.format(data.discountAmount)}',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Amount Paid',
            CurrencyFormatter.format(data.finalAmount),
            isTotal: true,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Order ID',
            data.orderId,
            valueStyle: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium)
              .copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              (isTotal ? AppTextStyles.h4 : AppTextStyles.bodyMedium).copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to order detail
              // For now, go to orders list
              context.go(AppRoutes.userOrders);
            },
            child: const Text('View Order'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(AppRoutes.userHome),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
            ),
            child: Text(
              'Go Home',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
