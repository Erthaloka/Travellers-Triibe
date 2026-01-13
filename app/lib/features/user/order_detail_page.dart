/// User Order Detail Page - Shows complete order information
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Order detail data model
class OrderDetail {
  final String orderId;
  final String merchantName;
  final String merchantCategory;
  final String merchantAddress;
  final double billAmount;
  final double discountPercent;
  final double discountAmount;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String status;
  final String paymentMethod;
  final String? transactionId;

  OrderDetail({
    required this.orderId,
    required this.merchantName,
    required this.merchantCategory,
    required this.merchantAddress,
    required this.billAmount,
    required this.discountPercent,
    required this.discountAmount,
    required this.amountPaid,
    required this.createdAt,
    this.paidAt,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
  });
}

/// User Order Detail Page
class UserOrderDetailPage extends StatelessWidget {
  final String orderId;

  const UserOrderDetailPage({super.key, required this.orderId});

  // Mock data for demo
  OrderDetail get _mockOrder => OrderDetail(
        orderId: orderId,
        merchantName: 'Spice Garden Restaurant',
        merchantCategory: 'FOOD',
        merchantAddress: 'Shop 12, MG Road, Mumbai 400001',
        billAmount: 1000.00,
        discountPercent: 6,
        discountAmount: 60.00,
        amountPaid: 940.00,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        paidAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'COMPLETED',
        paymentMethod: 'UPI',
        transactionId: 'pay_NxYz123456789',
      );

  @override
  Widget build(BuildContext context) {
    final order = _mockOrder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareOrder(context, order),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(order),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMerchantCard(order),
                  const SizedBox(height: 16),
                  _buildAmountBreakdown(order),
                  const SizedBox(height: 16),
                  _buildTransactionDetails(order),
                  const SizedBox(height: 16),
                  _buildActions(context, order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderDetail order) {
    final isCompleted = order.status == 'COMPLETED';
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusBgColor = isCompleted ? AppColors.successLight : AppColors.warningLight;

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
              isCompleted ? Icons.check_circle : Icons.schedule,
              color: statusColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isCompleted ? 'Payment Successful' : 'Payment Pending',
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

  Widget _buildMerchantCard(OrderDetail order) {
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
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(order.merchantCategory),
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.merchantName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.merchantAddress,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBreakdown(OrderDetail order) {
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
            'Payment Summary',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildAmountRow('Bill Amount', CurrencyFormatter.format(order.billAmount)),
          const SizedBox(height: 12),
          _buildAmountRow(
            'Discount (${order.discountPercent.toInt()}%)',
            '- ${CurrencyFormatter.format(order.discountAmount)}',
            valueColor: AppColors.success,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            'Amount Paid',
            CurrencyFormatter.format(order.amountPaid),
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.savingsGreenLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.savings_outlined,
                  color: AppColors.savingsGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'You saved ${CurrencyFormatter.format(order.discountAmount)}!',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.savingsGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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

  Widget _buildTransactionDetails(OrderDetail order) {
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
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.payment_outlined,
            'Payment Method',
            order.paymentMethod,
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
            'Paid At',
            order.paidAt != null
                ? DateTimeFormatter.formatDateTime(order.paidAt!)
                : '-',
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

  Widget _buildActions(BuildContext context, OrderDetail order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _downloadReceipt(context, order),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download Receipt'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _reportIssue(context, order),
            icon: Icon(Icons.help_outline, color: AppColors.textSecondary),
            label: Text(
              'Report an Issue',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD':
        return Icons.restaurant_outlined;
      case 'STAY':
        return Icons.hotel_outlined;
      case 'SERVICE':
        return Icons.build_outlined;
      case 'RETAIL':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  void _shareOrder(BuildContext context, OrderDetail order) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _downloadReceipt(BuildContext context, OrderDetail order) {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt download coming soon')),
    );
  }

  void _reportIssue(BuildContext context, OrderDetail order) {
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support feature coming soon')),
    );
  }
}
