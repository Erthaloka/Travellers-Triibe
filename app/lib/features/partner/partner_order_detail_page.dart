/// Partner Order Detail Page - Shows complete order info for merchant
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Partner order detail data model
class PartnerOrderDetail {
  final String orderId;
  final String userPhone;
  final double billAmount;
  final double discountPercent;
  final double discountAmount;
  final double platformFee;
  final double netReceivable;
  final DateTime createdAt;
  final DateTime? settledAt;
  final String status;
  final String settlementMode;
  final String? settlementId;
  final String paymentMethod;
  final String? transactionId;

  PartnerOrderDetail({
    required this.orderId,
    required this.userPhone,
    required this.billAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.platformFee,
    required this.netReceivable,
    required this.createdAt,
    this.settledAt,
    required this.status,
    required this.settlementMode,
    this.settlementId,
    required this.paymentMethod,
    this.transactionId,
  });
}

/// Partner Order Detail Page
class PartnerOrderDetailPage extends StatelessWidget {
  final String orderId;

  const PartnerOrderDetailPage({super.key, required this.orderId});

  // Mock data for demo
  PartnerOrderDetail get _mockOrder => PartnerOrderDetail(
        orderId: orderId,
        userPhone: '+91 ****3210',
        billAmount: 1000.00,
        discountPercent: 6,
        discountAmount: 60.00,
        platformFee: 9.40,
        netReceivable: 930.60,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        settledAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'SETTLED',
        settlementMode: 'PLATFORM',
        settlementId: 'STL_abc123xyz',
        paymentMethod: 'UPI',
        transactionId: 'pay_NxYz123456789',
      );

  @override
  Widget build(BuildContext context) {
    final order = _mockOrder;
    final isSettled = order.status == 'SETTLED';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(order, isSettled),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCustomerInfo(order),
                  const SizedBox(height: 16),
                  _buildEarningsBreakdown(order),
                  const SizedBox(height: 16),
                  _buildSettlementInfo(order, isSettled),
                  const SizedBox(height: 16),
                  _buildTransactionDetails(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(PartnerOrderDetail order, bool isSettled) {
    final statusColor = isSettled ? AppColors.success : AppColors.warning;
    final statusBgColor = isSettled ? AppColors.successLight : AppColors.warningLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusBgColor,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              boxShadow: AppShadows.small,
            ),
            child: Icon(
              isSettled ? Icons.check_circle : Icons.schedule,
              color: statusColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSettled ? 'Payment Settled' : 'Settlement Pending',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            DateTimeFormatter.formatDateTime(order.createdAt),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(PartnerOrderDetail order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.userPhone,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              order.paymentMethod,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdown(PartnerOrderDetail order) {
    return Container(
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
            'Earnings Breakdown',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('Bill Amount', CurrencyFormatter.format(order.billAmount)),
          const SizedBox(height: 12),
          _buildAmountRow(
            'Discount Funded (${order.discountPercent.toInt()}%)',
            '- ${CurrencyFormatter.format(order.discountAmount)}',
            valueColor: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            'Platform Fee (1%)',
            '- ${CurrencyFormatter.format(order.platformFee)}',
            valueColor: AppColors.textSecondary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            'Net Receivable',
            CurrencyFormatter.format(order.netReceivable),
            valueColor: AppColors.success,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium)
              .copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: (isTotal ? AppTextStyles.h4 : AppTextStyles.bodyMedium).copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementInfo(PartnerOrderDetail order, bool isSettled) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSettled ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSettled
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSettled ? Icons.account_balance : Icons.schedule,
                size: 20,
                color: isSettled ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Settlement Info',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSettled ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettlementRow('Mode', _getSettlementModeLabel(order.settlementMode)),
          if (isSettled) ...[
            const SizedBox(height: 10),
            _buildSettlementRow(
              'Settled On',
              order.settledAt != null
                  ? DateTimeFormatter.formatDateTime(order.settledAt!)
                  : '-',
            ),
          ] else ...[
            const SizedBox(height: 10),
            _buildSettlementRow('Expected', 'Within T+1 business day'),
          ],
          if (order.settlementId != null) ...[
            const SizedBox(height: 10),
            _buildSettlementRow('Settlement ID', order.settlementId!),
          ],
        ],
      ),
    );
  }

  Widget _buildSettlementRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(PartnerOrderDetail order) {
    return Container(
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
            'Transaction Details',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.receipt_outlined,
            'Order ID',
            order.orderId,
            canCopy: true,
          ),
          if (order.transactionId != null) ...[
            const SizedBox(height: 14),
            _buildDetailRow(
              Icons.tag_outlined,
              'Transaction ID',
              order.transactionId!,
              canCopy: true,
            ),
          ],
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.access_time,
            'Created At',
            DateTimeFormatter.formatDateTime(order.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool canCopy = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  if (canCopy)
                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$label copied'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy_outlined,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSettlementModeLabel(String mode) {
    switch (mode.toUpperCase()) {
      case 'PLATFORM':
        return 'Platform Settlement (T+1)';
      case 'DIRECT':
        return 'Direct to Razorpay';
      default:
        return mode;
    }
  }
}
