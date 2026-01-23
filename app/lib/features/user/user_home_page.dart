/// User home page with Scan & Pay, savings summary, and recent merchants
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travellers_triibe/features/user/user_notification.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/utils/formatters.dart';
import '../../routes/app_router.dart';

/// User home page - main landing for User role
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  bool _isLoading = true;
  int _totalSavings = 0;
  int _thisMonthSavings = 0;
  int _totalOrders = 0;
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
      // Fetch savings data
      final savingsResponse = await apiClient.get(ApiEndpoints.userSavings);

      if (savingsResponse.success && savingsResponse.data != null) {
        final data = savingsResponse.data!['data'] ?? savingsResponse.data!;
        setState(() {
          _totalSavings = (data['totalSavings'] as num?)?.toInt() ?? 0;
          _thisMonthSavings =
              ((data['thisMonth']?['savings'] as num?)?.toInt()) ?? 0;
          _totalOrders = (data['totalOrders'] as num?)?.toInt() ?? 0;
          _recentOrders = (data['recentSavings'] as List?) ?? [];
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Scrollable Content
            RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(child: _buildAppBar(context)),
                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 10), // Small gap after app bar
                        _buildSavingsCard(context),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildRecentOrdersSection(context),
                        // Extra space at bottom so button doesn't cover content
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Scan & Pay Button in Bottom Right
            Positioned(
              bottom: 24,
              right: 20,
              child: _buildScanPayButton(context),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travellers Triibe',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Hey, ${_getGreeting()}!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // --- FIXED: DYNAMIC NOTIFICATION BELL ---
          ListenableBuilder(
            listenable: notificationService, // Listens to your global service
            builder: (context, child) {
              // Checks real-time unread status
              final bool hasUnread = notificationService.notifications.any(
                (n) => !n['isRead'],
              );

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.notification),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                  // The red dot now only appears if hasUnread is true
                  if (hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 4),

          // Profile Icon
          GestureDetector(
            onTap: () => context.go(AppRoutes.userProfile),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  account?.name.isNotEmpty == true
                      ? account!.name[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // UPDATED: Changed to a compact floating design for the corner
  Widget _buildScanPayButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.go(AppRoutes.scan),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan & Pay',
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

  Widget _buildSavingsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.userSavings),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.savingsGreenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: AppColors.savingsGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Your Savings',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Center(
                child: SizedBox(
                  height: 44,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildSavingsItem('Orders', _totalOrders.toString()),
                  ),
                  Container(width: 1, height: 44, color: AppColors.border),
                  Expanded(
                    child: _buildSavingsItem(
                      'This Month',
                      CurrencyFormatter.format(_thisMonthSavings / 100),
                    ),
                  ),
                  Container(width: 1, height: 44, color: AppColors.border),
                  Expanded(
                    child: _buildSavingsItem(
                      'Lifetime',
                      CurrencyFormatter.format(_totalSavings / 100),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsItem(String label, String amount) {
    return Column(
      children: [
        Text(
          amount,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.savingsGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            color: AppColors.info,
            onTap: () => context.go(AppRoutes.userOrders),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.history_outlined,
            label: 'History',
            color: AppColors.warning,
            onTap: () => context.go(AppRoutes.userOrders),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.help_outline,
            label: 'Support',
            color: AppColors.success,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context) {
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
              onPressed: () => context.go(AppRoutes.userOrders),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          ..._recentOrders.map((order) => _buildOrderItem(context, order)),
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
            'Scan a QR code to start saving!',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, dynamic order) {
    final partner = order['partnerId'];
    final businessName = partner?['businessName'] ?? 'Unknown Merchant';
    final category = partner?['category'] ?? 'OTHER';
    final discountAmount = (order['discountAmount'] as num?)?.toDouble() ?? 0;
    final createdAt =
        DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
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
                'Saved',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyFormatter.format(discountAmount / 100),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.savingsGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD':
        return Icons.restaurant_outlined;
      case 'STAY':
        return Icons.hotel_outlined;
      case 'SERVICE':
        return Icons.build_outlined;
      case 'RETAIL':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'FOOD':
        return const Color(0xFFFF6B6B);
      case 'STAY':
        return const Color(0xFF4ECDC4);
      case 'SERVICE':
        return const Color(0xFF9B59B6);
      case 'RETAIL':
        return const Color(0xFF3498DB);
      default:
        return AppColors.primary;
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
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Orders',
                isActive: false,
                onTap: () => context.go(AppRoutes.userOrders),
              ),
              _buildNavItem(
                icon: Icons.savings_outlined,
                activeIcon: Icons.savings,
                label: 'Savings',
                isActive: false,
                onTap: () => context.go(AppRoutes.userSavings),
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () => context.go(AppRoutes.userProfile),
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
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
