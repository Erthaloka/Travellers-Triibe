/// Partner orders page - order history for merchant
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// Partner order model
class PartnerOrder {
  final String orderId;
  final String userPhone;
  final double billAmount;
  final double discountAmount;
  final double platformFee;
  final double netReceivable;
  final DateTime date;
  final String status;
  final String settlementMode;

  PartnerOrder({
    required this.orderId,
    required this.userPhone,
    required this.billAmount,
    required this.discountAmount,
    required this.platformFee,
    required this.netReceivable,
    required this.date,
    required this.status,
    required this.settlementMode,
  });
}

/// Partner orders page
class PartnerOrdersPage extends StatefulWidget {
  const PartnerOrdersPage({super.key});

  @override
  State<PartnerOrdersPage> createState() => _PartnerOrdersPageState();
}

class _PartnerOrdersPageState extends State<PartnerOrdersPage> {
  String _selectedFilter = 'all';

  // --- MOCK DATA ADDED HERE ---
  final List<PartnerOrder> _mockOrders = [
    PartnerOrder(
      orderId: 'ORD88219',
      userPhone: '+91 98765 43210',
      billAmount: 1250.0,
      discountAmount: 150.0,
      platformFee: 25.0,
      netReceivable: 1075.0,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'PENDING',
      settlementMode: 'UPI',
    ),
    PartnerOrder(
      orderId: 'ORD88104',
      userPhone: '+91 70123 45678',
      billAmount: 500.0,
      discountAmount: 50.0,
      platformFee: 10.0,
      netReceivable: 440.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'SETTLED',
      settlementMode: 'Bank Transfer',
    ),
    PartnerOrder(
      orderId: 'ORD87992',
      userPhone: '+91 90000 11111',
      billAmount: 2100.0,
      discountAmount: 300.0,
      platformFee: 40.0,
      netReceivable: 1760.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: 'SETTLED',
      settlementMode: 'UPI',
    ),
  ];

  List<PartnerOrder> get _filteredOrders {
    if (_selectedFilter == 'all') return _mockOrders;
    // Filters based on the status string
    return _mockOrders
        .where((o) => o.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.partnerDashboard),
        ),
        title: const Text('Orders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildSummaryBar(),
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All'),
            const SizedBox(width: 8),
            // Changed value to 'pending' to match mock data status
            _buildFilterChip('pending', 'Pending'),
            const SizedBox(width: 8),
            _buildFilterChip('settled', 'Settled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.partnerAccent.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.partnerAccent : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.partnerAccent : AppColors.border,
      ),
      checkmarkColor: AppColors.partnerAccent,
    );
  }

  Widget _buildSummaryBar() {
    final totalOrders = _filteredOrders.length;
    final totalAmount = _filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.netReceivable,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalOrders Orders',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Total receivable',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(totalAmount),
            style: AppTextStyles.h3.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(PartnerOrder order) {
    final isSettled = order.status == 'SETTLED';

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          context.go('/partner/orders/${order.orderId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isSettled ? AppColors.success : AppColors.warning)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isSettled ? Icons.check_circle : Icons.schedule,
                      color: isSettled ? AppColors.success : AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.orderId,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isSettled
                                            ? AppColors.success
                                            : AppColors.warning)
                                        .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSettled ? 'Settled' : 'Pending',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSettled
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.userPhone} • ${DateTimeFormatter.formatRelative(order.date)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildOrderStat(
                    'Bill',
                    CurrencyFormatter.format(order.billAmount),
                  ),
                  _buildOrderStat(
                    'Discount',
                    '-${CurrencyFormatter.format(order.discountAmount)}',
                    color: AppColors.warning,
                  ),
                  _buildOrderStat(
                    'Net',
                    CurrencyFormatter.format(order.netReceivable),
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a bill to start receiving payments',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.generateQr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.partnerAccent,
            ),
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate Bill'),
          ),
        ],
      ),
    );
  }
}
