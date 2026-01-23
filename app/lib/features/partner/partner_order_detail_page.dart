/// Partner Order Detail Page - Shows complete order info for merchant
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Partner Order Detail Page
class PartnerOrderDetailPage extends StatefulWidget {
  final String orderId;

  const PartnerOrderDetailPage({super.key, required this.orderId});

  @override
  State<PartnerOrderDetailPage> createState() => _PartnerOrderDetailPageState();
}

class _PartnerOrderDetailPageState extends State<PartnerOrderDetailPage> {
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
    final status = order['status'] ?? 'PENDING';
    final isSettled = status == 'COMPLETED';

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

  Widget _buildStatusHeader(Map<String, dynamic> order, bool isSettled) {
    final statusColor = isSettled ? AppColors.success : AppColors.warning;
    final statusBgColor = isSettled ? AppColors.successLight : AppColors.warningLight;
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
              isSettled ? Icons.check_circle : Icons.schedule,
              color: statusColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSettled ? 'Payment Completed' : 'Payment Pending',
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

  Widget _buildCustomerInfo(Map<String, dynamic> order) {
    final user = order['userId'];
    final userPhone = user?['phone'] ?? 'Unknown';
    final paymentMethod = order['paymentMethod'] ?? 'UPI';

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
                  userPhone,
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
              paymentMethod,
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

  Widget _buildEarningsBreakdown(Map<String, dynamic> order) {
    final originalAmount = (order['originalAmount'] as num?)?.toDouble() ?? 0;
    final discountRate = (order['discountRate'] as num?)?.toDouble() ?? 0;
    final discountAmount = (order['discountAmount'] as num?)?.toDouble() ?? 0;
    final platformFee = (order['platformFee'] as num?)?.toDouble() ?? 0;
    final partnerPayout = (order['partnerPayout'] as num?)?.toDouble() ?? 0;

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
          _buildAmountRow('Bill Amount', CurrencyFormatter.format(originalAmount / 100)),
          const SizedBox(height: 12),
          _buildAmountRow(
            'Discount Funded (${discountRate.toInt()}%)',
            '- ${CurrencyFormatter.format(discountAmount / 100)}',
            valueColor: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            'Platform Fee (1%)',
            '- ${CurrencyFormatter.format(platformFee / 100)}',
            valueColor: AppColors.textSecondary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            'Net Receivable',
            CurrencyFormatter.format(partnerPayout / 100),
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

  Widget _buildSettlementInfo(Map<String, dynamic> order, bool isSettled) {
    final settlementMode = order['settlementMode'] ?? 'PLATFORM';
    final completedAt = order['completedAt'] != null
        ? DateTime.tryParse(order['completedAt'])
        : null;

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
          _buildSettlementRow('Mode', _getSettlementModeLabel(settlementMode)),
          if (isSettled && completedAt != null) ...[
            const SizedBox(height: 10),
            _buildSettlementRow(
              'Completed On',
              DateTimeFormatter.formatDateTime(completedAt),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _buildSettlementRow('Expected', 'Within T+1 business day'),
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

  Widget _buildTransactionDetails(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? widget.orderId;
    final razorpayPaymentId = order['razorpayPaymentId'];
    final createdAt = DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

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
            'Created At',
            DateTimeFormatter.formatDateTime(createdAt),
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