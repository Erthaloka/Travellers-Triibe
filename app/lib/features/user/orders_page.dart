/// User orders page - order history with filtering
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// Order category filter
enum OrderCategory { all, food, stay, service, retail }

/// Mock order model for demo
class MockOrder {
  final String orderId;
  final String merchantName;
  final String category;
  final double amountPaid;
  final double discountAmount;
  final DateTime date;
  final String status;

  MockOrder({
    required this.orderId,
    required this.merchantName,
    required this.category,
    required this.amountPaid,
    required this.discountAmount,
    required this.date,
    required this.status,
  });
}

/// User orders page
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  OrderCategory _selectedCategory = OrderCategory.all;

  // Mock orders for demo
  final List<MockOrder> _mockOrders = [
    MockOrder(
      orderId: 'ORD001',
      merchantName: 'Spice Garden Restaurant',
      category: 'FOOD',
      amountPaid: 940,
      discountAmount: 60,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'COMPLETED',
    ),
    MockOrder(
      orderId: 'ORD002',
      merchantName: 'Hotel Sunrise',
      category: 'STAY',
      amountPaid: 4700,
      discountAmount: 300,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'COMPLETED',
    ),
    MockOrder(
      orderId: 'ORD003',
      merchantName: 'City Spa & Wellness',
      category: 'SERVICE',
      amountPaid: 1880,
      discountAmount: 120,
      date: DateTime.now().subtract(const Duration(days: 3)),
      status: 'COMPLETED',
    ),
  ];

  List<MockOrder> get _filteredOrders {
    if (_selectedCategory == OrderCategory.all) return _mockOrders;
    return _mockOrders
        .where((o) =>
            o.category.toLowerCase() == _selectedCategory.name.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.userHome),
        ),
        title: const Text('My Orders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: OrderCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getCategoryLabel(category)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: AppColors.surfaceVariant,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                checkmarkColor: AppColors.primary,
              ),
            );
          }).toList(),
        ),
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

  Widget _buildOrderCard(MockOrder order) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // Navigate to order detail
          context.go('/user/orders/${order.orderId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(order.category),
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.merchantName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeFormatter.formatRelative(order.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(order.amountPaid),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Saved ${CurrencyFormatter.format(order.discountAmount)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a QR code to make your first payment',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.scan),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan & Pay'),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(OrderCategory category) {
    switch (category) {
      case OrderCategory.all:
        return 'All';
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
}
