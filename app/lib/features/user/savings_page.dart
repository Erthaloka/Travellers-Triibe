/// User Savings Page - Shows lifetime savings and breakdown-savings_page.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../routes/app_router.dart';

/// User Savings Page
class UserSavingsPage extends StatefulWidget {
  const UserSavingsPage({super.key});

  @override
  State<UserSavingsPage> createState() => _UserSavingsPageState();
}

class _UserSavingsPageState extends State<UserSavingsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _savingsData = {};

  @override
  void initState() {
    super.initState();
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.userSavings);

      if (response.success && response.data != null) {
        setState(() {
          _savingsData = response.data!['data'] ?? response.data!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load savings: $e')),
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
            onPressed: () => context.go(AppRoutes.userHome),
          ),
          title: const Text('My Savings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalSavings = (_savingsData['totalSavings'] as num?)?.toDouble() ?? 0;
    final totalOrders = (_savingsData['totalOrders'] as num?)?.toInt() ?? 0;
    final thisMonth = _savingsData['thisMonth'] ?? {};
    final thisMonthSavings = (thisMonth['savings'] as num?)?.toDouble() ?? 0;
    final growthPercentage = (_savingsData['growthPercentage'] as num?)?.toDouble() ?? 0;
    final categorySavings = (_savingsData['categorySavings'] as List?) ?? [];
    final monthlySavings = (_savingsData['monthlySavings'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.userHome),
        ),
        title: const Text('My Savings'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavings,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSavingsHeader(totalSavings),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(totalOrders, thisMonthSavings, growthPercentage),
                    const SizedBox(height: 24),
                    if (categorySavings.isNotEmpty) ...[
                      _buildCategoryBreakdown(categorySavings),
                      const SizedBox(height: 24),
                    ],
                    if (monthlySavings.isNotEmpty)
                      _buildMonthlyHistory(monthlySavings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsHeader(double totalSavings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.savingsGreen,
            AppColors.savingsGreen.withOpacity(0.85),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Total Savings',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalSavings / 100),
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Lifetime savings with Travellers Triibe',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalOrders, double thisMonthSavings, double growth) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long_outlined,
            value: '$totalOrders',
            label: 'Total Orders',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today_outlined,
            value: CurrencyFormatter.formatCompact(thisMonthSavings / 100),
            label: 'This Month',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<dynamic> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final maxSavings = categories.fold<double>(
      0,
          (max, cat) => ((cat['savings'] as num?)?.toDouble() ?? 0) > max
          ? ((cat['savings'] as num?)?.toDouble() ?? 0)
          : max,
    );

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
            'Savings by Category',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map((cat) {
            final category = cat['_id'] ?? 'OTHER';
            final savings = (cat['savings'] as num?)?.toDouble() ?? 0;
            final progress = maxSavings > 0 ? savings / maxSavings : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCategoryRow(category, savings, progress),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, double amount, double progress) {
    final categoryInfo = _getCategoryInfo(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              categoryInfo.icon,
              size: 18,
              color: categoryInfo.color,
            ),
            const SizedBox(width: 8),
            Text(
              categoryInfo.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(amount / 100),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(categoryInfo.color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyHistory(List<dynamic> monthlyData) {
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
            'Monthly History',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...monthlyData.map((month) {
            final monthId = month['_id'];
            final savings = (month['savings'] as num?)?.toDouble() ?? 0;
            final orders = (month['orders'] as num?)?.toInt() ?? 0;
            final monthName = _getMonthName(monthId);

            return _buildMonthRow(monthName, savings, orders);
          }),
        ],
      ),
    );
  }

  Widget _buildMonthRow(String monthName, double amount, int orders) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$orders orders',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount / 100),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(dynamic monthId) {
    if (monthId is int) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return monthId > 0 && monthId <= 12 ? months[monthId - 1] : 'Unknown';
    }
    return monthId.toString();
  }

  _CategoryInfo _getCategoryInfo(String category) {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
      case 'CAFE':
      case 'FOOD':
        return _CategoryInfo(
          icon: Icons.restaurant_outlined,
          label: 'Food & Dining',
          color: const Color(0xFFFF6B6B),
        );
      case 'HOTEL':
      case 'STAY':
        return _CategoryInfo(
          icon: Icons.hotel_outlined,
          label: 'Hotels & Stay',
          color: const Color(0xFF4ECDC4),
        );
      case 'SALON':
      case 'GYM':
      case 'SERVICE':
        return _CategoryInfo(
          icon: Icons.build_outlined,
          label: 'Services',
          color: const Color(0xFF9B59B6),
        );
      case 'RETAIL':
        return _CategoryInfo(
          icon: Icons.shopping_bag_outlined,
          label: 'Retail',
          color: const Color(0xFF3498DB),
        );
      default:
        return _CategoryInfo(
          icon: Icons.store_outlined,
          label: category,
          color: AppColors.primary,
        );
    }
  }
}

class _CategoryInfo {
  final IconData icon;
  final String label;
  final Color color;

  _CategoryInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}