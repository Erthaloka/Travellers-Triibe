/// Partner analytics page - earnings and statistics
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// Partner analytics page
class PartnerAnalyticsPage extends StatefulWidget {
  const PartnerAnalyticsPage({super.key});

  @override
  State<PartnerAnalyticsPage> createState() => _PartnerAnalyticsPageState();
}

class _PartnerAnalyticsPageState extends State<PartnerAnalyticsPage> {
  String _selectedPeriod = 'month';

  // Mock analytics data
  final Map<String, Map<String, dynamic>> _analyticsData = {
    'today': {
      'orders': 12,
      'revenue': 15600.0,
      'discountGiven': 936.0,
      'platformFee': 146.64,
      'netEarnings': 14517.36,
      'repeatUsers': 3,
    },
    'week': {
      'orders': 68,
      'revenue': 89200.0,
      'discountGiven': 5352.0,
      'platformFee': 838.48,
      'netEarnings': 83009.52,
      'repeatUsers': 15,
    },
    'month': {
      'orders': 284,
      'revenue': 372000.0,
      'discountGiven': 22320.0,
      'platformFee': 3496.80,
      'netEarnings': 346183.20,
      'repeatUsers': 48,
    },
  };

  Map<String, dynamic> get _currentData =>
      _analyticsData[_selectedPeriod] ?? _analyticsData['month']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.partnerDashboard),
        ),
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildEarningsCard(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildBreakdownCard(),
            const SizedBox(height: 24),
            _buildInsightsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('today', 'Today'),
          _buildPeriodButton('week', 'This Week'),
          _buildPeriodButton('month', 'This Month'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.partnerAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPeriod = value;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.partnerAccent,
            AppColors.partnerAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Earnings',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(_currentData['netEarnings']),
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildEarningsStat(
                'Orders',
                _currentData['orders'].toString(),
              ),
              const SizedBox(width: 24),
              _buildEarningsStat(
                'Repeat Users',
                _currentData['repeatUsers'].toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.currency_rupee,
            label: 'Total Revenue',
            value: CurrencyFormatter.formatCompact(_currentData['revenue']),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_offer,
            label: 'Discounts Given',
            value: CurrencyFormatter.formatCompact(_currentData['discountGiven']),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
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

  Widget _buildBreakdownCard() {
    return Container(
      width: double.infinity,
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
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow(
            'Gross Revenue',
            CurrencyFormatter.format(_currentData['revenue']),
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            'Discount Funded',
            '-${CurrencyFormatter.format(_currentData['discountGiven'])}',
            valueColor: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            'Platform Fee (1%)',
            '-${CurrencyFormatter.format(_currentData['platformFee'])}',
            valueColor: AppColors.textSecondary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildBreakdownRow(
            'Net Earnings',
            CurrencyFormatter.format(_currentData['netEarnings']),
            valueColor: AppColors.success,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
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
              .copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (isTotal ? AppTextStyles.h4 : AppTextStyles.bodyMedium)
              .copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Insights',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '${_currentData['repeatUsers']} repeat customers this period',
            Icons.people,
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            'Average order value: ${CurrencyFormatter.format(_currentData['revenue'] / _currentData['orders'])}',
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            'Discount investment: ${((_currentData['discountGiven'] / _currentData['revenue']) * 100).toStringAsFixed(1)}% of revenue',
            Icons.savings,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
