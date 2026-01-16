/// User Order Detail Page - Shows complete order information - order_detail_page.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// User Order Detail Page
class UserOrderDetailPage extends StatefulWidget {
  final String orderId;

  const UserOrderDetailPage({super.key, required this.orderId});

  @override
  State<UserOrderDetailPage> createState() => _UserOrderDetailPageState();
}

class _UserOrderDetailPageState extends State<UserOrderDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get(
        '${ApiEndpoints.orders}/${widget.orderId}',
      );

      if (response.success && response.data != null) {
        setState(() {
          _orderData = response.data!['data'] ?? response.data!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Order Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_orderData == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Order Details'),
        ),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = _orderData!;

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

  Widget _buildStatusHeader(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final isCompleted = status == 'COMPLETED';
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusBgColor = isCompleted ? AppColors.successLight : AppColors.warningLight;
    final createdAt = DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

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
            DateTimeFormatter.formatDateTime(createdAt),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> order) {
    final partner = order['partnerId'];
    final businessName = partner?['businessName'] ?? 'Unknown Merchant';
    final category = partner?['category'] ?? 'OTHER';
    final address = partner?['address'];
    final city = address?['city'] ?? '';

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
              _getCategoryIcon(category),
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
                  businessName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  city,
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

  Widget _buildAmountBreakdown(Map<String, dynamic> order) {
    final originalAmount = (order['originalAmount'] as num?)?.toDouble() ?? 0;
    final discountRate = (order['discountRate'] as num?)?.toDouble() ?? 0;
    final discountAmount = (order['discountAmount'] as num?)?.toDouble() ?? 0;
    final finalAmount = (order['finalAmount'] as num?)?.toDouble() ?? 0;

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
          _buildAmountRow('Bill Amount', CurrencyFormatter.format(originalAmount / 100)),
          const SizedBox(height: 12),
          _buildAmountRow(
            'Discount (${discountRate.toInt()}%)',
            '- ${CurrencyFormatter.format(discountAmount / 100)}',
            valueColor: AppColors.success,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            'Amount Paid',
            CurrencyFormatter.format(finalAmount / 100),
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
                  'You saved ${CurrencyFormatter.format(discountAmount / 100)}!',
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

  Widget _buildTransactionDetails(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? widget.orderId;
    final paymentMethod = order['paymentMethod'] ?? 'UPI';
    final razorpayPaymentId = order['razorpayPaymentId'];
    final completedAt = order['completedAt'] != null
        ? DateTime.tryParse(order['completedAt'])
        : null;

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
            orderId,
            canCopy: true,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.payment_outlined,
            'Payment Method',
            paymentMethod,
          ),
          if (razorpayPaymentId != null) ...[
            const SizedBox(height: 14),
            _buildDetailRow(
              Icons.tag_outlined,
              'Transaction ID',
              razorpayPaymentId,
              canCopy: true,
            ),
          ],
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.access_time,
            'Paid At',
            completedAt != null
                ? DateTimeFormatter.formatDateTime(completedAt)
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
                    GestureDetector(
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
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Map<String, dynamic> order) {
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
      case 'RESTAURANT':
      case 'CAFE':
      case 'FOOD':
        return Icons.restaurant_outlined;
      case 'HOTEL':
      case 'STAY':
        return Icons.hotel_outlined;
      case 'SALON':
      case 'GYM':
      case 'SERVICE':
        return Icons.build_outlined;
      case 'RETAIL':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  void _shareOrder(BuildContext context, Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _downloadReceipt(BuildContext context, Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt download coming soon')),
    );
  }

  void _reportIssue(BuildContext context, Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support feature coming soon')),
    );
  }
}