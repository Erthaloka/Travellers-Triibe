/// User Savings Page - Shows lifetime savings and breakdown
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// Savings summary data
class SavingsSummary {
  final double totalSavings;
  final int totalOrders;
  final double averageDiscount;
  final Map<String, double> categoryBreakdown;
  final List<MonthlySaving> monthlyHistory;

  SavingsSummary({
    required this.totalSavings,
    required this.totalOrders,
    required this.averageDiscount,
    required this.categoryBreakdown,
    required this.monthlyHistory,
  });
}

class MonthlySaving {
  final String month;
  final double amount;
  final int orders;

  MonthlySaving({
    required this.month,
    required this.amount,
    required this.orders,
  });
}

/// User Savings Page
class UserSavingsPage extends StatelessWidget {
  const UserSavingsPage({super.key});

  // Mock data for demo
  SavingsSummary get _mockSavings => SavingsSummary(
        totalSavings: 12450.00,
        totalOrders: 156,
        averageDiscount: 5.8,
        categoryBreakdown: {
          'FOOD': 5200.00,
          'STAY': 4800.00,
          'SERVICE': 1650.00,
          'RETAIL': 800.00,
        },
        monthlyHistory: [
          MonthlySaving(month: 'Dec 2024', amount: 2340.00, orders: 28),
          MonthlySaving(month: 'Nov 2024', amount: 1890.00, orders: 24),
          MonthlySaving(month: 'Oct 2024', amount: 2100.00, orders: 26),
          MonthlySaving(month: 'Sep 2024', amount: 1750.00, orders: 22),
          MonthlySaving(month: 'Aug 2024', amount: 2050.00, orders: 25),
          MonthlySaving(month: 'Jul 2024', amount: 2320.00, orders: 31),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final savings = _mockSavings;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.userHome),
        ),
        title: const Text('My Savings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSavingsHeader(savings),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(savings),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(savings),
                  const SizedBox(height: 24),
                  _buildMonthlyHistory(savings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsHeader(SavingsSummary savings) {
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
            CurrencyFormatter.format(savings.totalSavings),
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

  Widget _buildStatsRow(SavingsSummary savings) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt_long_outlined,
            value: '${savings.totalOrders}',
            label: 'Total Orders',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.percent_outlined,
            value: '${savings.averageDiscount.toStringAsFixed(1)}%',
            label: 'Avg Discount',
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

  Widget _buildCategoryBreakdown(SavingsSummary savings) {
    final categories = savings.categoryBreakdown;
    final maxAmount = categories.values.reduce((a, b) => a > b ? a : b);

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
          ...categories.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCategoryRow(
                  entry.key,
                  entry.value,
                  entry.value / maxAmount,
                ),
              )),
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
              CurrencyFormatter.format(amount),
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

  Widget _buildMonthlyHistory(SavingsSummary savings) {
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
          ...savings.monthlyHistory
              .map((month) => _buildMonthRow(month))
              ,
        ],
      ),
    );
  }

  Widget _buildMonthRow(MonthlySaving month) {
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
                  month.month,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${month.orders} orders',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(month.amount),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _CategoryInfo _getCategoryInfo(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD':
        return _CategoryInfo(
          icon: Icons.restaurant_outlined,
          label: 'Food & Dining',
          color: const Color(0xFFFF6B6B),
        );
      case 'STAY':
        return _CategoryInfo(
          icon: Icons.hotel_outlined,
          label: 'Hotels & Stay',
          color: const Color(0xFF4ECDC4),
        );
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
