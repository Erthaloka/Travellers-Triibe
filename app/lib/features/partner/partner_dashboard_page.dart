/// Partner dashboard page with today's stats and quick actions
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// Partner dashboard - main landing for Partner role
class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  bool _isLoading = true;
  int _todayOrders = 0;
  int _todayRevenue = 0;
  int _todayDiscount = 0;
  int _pendingAmount = 0;
  String _businessName = '';
  List<dynamic> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final apiClient = context.read<ApiClient>();

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch partner profile
      final profileResponse = await apiClient.get(ApiEndpoints.partnerProfile);
      if (profileResponse.success && profileResponse.data != null) {
        final data = profileResponse.data!['data'] ?? profileResponse.data!;
        setState(() {
          _businessName = data['businessName'] ?? '';
        });
      }

      // Fetch partner analytics/stats
      final analyticsResponse = await apiClient.get(
        ApiEndpoints.partnerAnalytics,
      );
      if (analyticsResponse.success && analyticsResponse.data != null) {
        final data = analyticsResponse.data!['data'] ?? analyticsResponse.data!;
        final today = data['today'] ?? {};
        setState(() {
          _todayOrders = (today['orders'] as num?)?.toInt() ?? 0;
          _todayRevenue = (today['revenue'] as num?)?.toInt() ?? 0;
          _todayDiscount = (today['discountGiven'] as num?)?.toInt() ?? 0;
          _pendingAmount = (data['pendingSettlement'] as num?)?.toInt() ?? 0;
        });
      }

      // Fetch recent orders
      final ordersResponse = await apiClient.get(
        ApiEndpoints.partnerOrders,
        queryParams: {'limit': '5'},
      );
      if (ordersResponse.success && ordersResponse.data != null) {
        final data = ordersResponse.data!['data'] ?? ordersResponse.data!;
        setState(() {
          _recentOrders = (data['orders'] as List?) ?? [];
        });
      }
    } catch (e) {
      // Silently fail - show zeros
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main Scrollable Content
            RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildAppBar(context)),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTodayStats(),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildRecentOrders(context),
                        // Bottom spacing so floating button doesn't cover last order
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Generate Bill Button in Bottom Right
            Positioned(
              bottom: 24,
              right: 20,
              child: _buildGenerateBillButton(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final account = context.watch<AuthProvider>().account;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.partnerAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessName.isNotEmpty
                      ? _businessName
                      : 'Partner Dashboard',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _businessName.isNotEmpty
                      ? 'Partner Dashboard'
                      : (account?.email ?? 'Business'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go(AppRoutes.partnerProfile),
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated: Now formatted as a Floating Action Button for the bottom right
  Widget _buildGenerateBillButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.partnerAccent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: AppColors.partnerAccent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => context.go(AppRoutes.generateQr),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  'Generate QR',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Overview",
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.receipt_long,
                  label: 'Orders',
                  value: _todayOrders.toString(),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.currency_rupee,
                  label: 'Revenue',
                  value: CurrencyFormatter.formatCompact(_todayRevenue / 100),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_offer,
                  label: 'Discount Given',
                  value: CurrencyFormatter.formatCompact(_todayDiscount / 100),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Pending',
                  value: CurrencyFormatter.formatCompact(_pendingAmount / 100),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
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

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                onTap: () => context.go(AppRoutes.partnerOrders),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () => context.go(AppRoutes.partnerAnalytics),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.go(AppRoutes.partnerProfile),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.partnerOrders),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_recentOrders.isEmpty)
          _buildEmptyOrders()
        else
          ..._recentOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOrderItem(order),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyOrders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'No orders yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate a QR code to start receiving orders',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic order) {
    final orderId = order['orderId'] ?? 'Unknown';
    final originalAmount = (order['originalAmount'] as num?)?.toDouble() ?? 0;
    final discountAmount = (order['discountAmount'] as num?)?.toDouble() ?? 0;
    final status = order['status'] ?? 'PENDING';
    final createdAt =
        DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatTimeAgo(createdAt),
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
                CurrencyFormatter.format(originalAmount / 100),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '-${CurrencyFormatter.format(discountAmount / 100)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.access_time;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.receipt_long;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.qr_code_outlined,
                activeIcon: Icons.qr_code,
                label: 'Generate',
                isActive: false,
                onTap: () => context.go(AppRoutes.generateQr),
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Orders',
                isActive: false,
                onTap: () => context.go(AppRoutes.partnerOrders),
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () => context.go(AppRoutes.partnerProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? AppColors.partnerAccent
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive
                    ? AppColors.partnerAccent
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
