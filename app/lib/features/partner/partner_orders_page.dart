/// Partner orders page - order history for merchant - partner_orders_page.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../routes/app_router.dart';

/// Partner orders page
class PartnerOrdersPage extends StatefulWidget {
  const PartnerOrdersPage({super.key});

  @override
  State<PartnerOrdersPage> createState() => _PartnerOrdersPageState();
}

class _PartnerOrdersPageState extends State<PartnerOrdersPage> {
  String _selectedFilter = 'all';
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
      final queryParams = <String, String>{};

      if (_selectedFilter != 'all') {
        queryParams['status'] = _selectedFilter.toUpperCase();
      }

      final response = await apiClient.get(
        ApiEndpoints.partnerOrders,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] ?? response.data!;
        setState(() {
          _orders = (data['orders'] as List?) ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
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
            _buildFilterChip('pending', 'Pending'),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Completed'),
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
        _loadOrders();
      },
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.partnerAccent.withValues(alpha: 0.2),
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
    final totalOrders = _orders.length;
    final totalAmount = _orders.fold<double>(
      0,
          (sum, order) => sum + ((order['partnerPayout'] as num?)?.toDouble() ?? 0),
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
            CurrencyFormatter.format(totalAmount / 100),
            style: AppTextStyles.h3.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final isCompleted = status == 'COMPLETED';
    // ✅ FIXED: Use orderId field directly (TT-XXXXXX format)
    final orderId = order['orderId'] as String? ?? 'Unknown';
    final user = order['userId'];
    final userPhone = user?['phone'] ?? 'Unknown';
    final originalAmount = (order['originalAmount'] as num?)?.toDouble() ?? 0;
    final discountAmount = (order['discountAmount'] as num?)?.toDouble() ?? 0;
    final partnerPayout = (order['partnerPayout'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // ✅ FIXED: Now passing correct orderId (TT-XXXXXX)
          context.go('/partner/orders/$orderId');
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
                      color: (isCompleted ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      color: isCompleted ? AppColors.success : AppColors.warning,
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
                              orderId,
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
                                color: (isCompleted
                                    ? AppColors.success
                                    : AppColors.warning)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Pending',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isCompleted
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$userPhone • ${DateTimeFormatter.formatRelative(createdAt)}',
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
                  _buildOrderStat('Bill', CurrencyFormatter.format(originalAmount / 100)),
                  _buildOrderStat(
                    'Discount',
                    '-${CurrencyFormatter.format(discountAmount / 100)}',
                    color: AppColors.warning,
                  ),
                  _buildOrderStat(
                    'Net',
                    CurrencyFormatter.format(partnerPayout / 100),
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
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a bill to start receiving payments',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
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