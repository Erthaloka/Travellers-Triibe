/// User orders page - order history with filtering - orders_page.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../routes/app_router.dart';

/// Order category filter
enum OrderCategory { all, restaurant, hotel, salon, retail }

/// User orders page
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  OrderCategory _selectedCategory = OrderCategory.all;
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.orders);

      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data!;
        setState(() {
          _orders = (data['orders'] as List?) ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredOrders {
    if (_selectedCategory == OrderCategory.all) return _orders;

    final categoryFilter = _selectedCategory.name.toUpperCase();
    return _orders.where((order) {
      final partner = order['partnerId'];
      final category = (partner?['category'] as String?)?.toUpperCase() ?? '';
      return category == categoryFilter;
    }).toList();
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
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
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
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
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // ✅ FIXED: Use orderId field directly (TT-XXXXXX format)
    final orderId = order['orderId'] as String? ?? 'Unknown';
    final partner = order['partnerId'];
    final merchantName = partner?['businessName'] ?? 'Unknown Merchant';
    final category = partner?['category'] ?? 'OTHER';
    final finalAmount = (order['finalAmount'] as num?)?.toDouble() ?? 0;
    final discountAmount = (order['discountAmount'] as num?)?.toDouble() ?? 0;
    final createdAt =
        DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // ✅ FIXED: Now passing correct orderId (TT-XXXXXX)
          context.go('/user/orders/$orderId');
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
                      _getCategoryIcon(category),
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
                          merchantName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTimeFormatter.formatRelative(createdAt),
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
                        CurrencyFormatter.format(finalAmount / 100),
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
                          'Saved ${CurrencyFormatter.format(discountAmount / 100)}',
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
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a QR code to make your first payment',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
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
      case OrderCategory.restaurant:
        return 'Food';
      case OrderCategory.hotel:
        return 'Hotel';
      case OrderCategory.salon:
        return 'Services';
      case OrderCategory.retail:
        return 'Retail';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
      case 'CAFE':
      case 'FOOD':
        return Icons.restaurant;
      case 'HOTEL':
      case 'STAY':
        return Icons.hotel;
      case 'SALON':
      case 'GYM':
      case 'SERVICE':
        return Icons.miscellaneous_services;
      case 'RETAIL':
        return Icons.shopping_bag;
      default:
        return Icons.store;
    }
  }
}