/// User profile page with account info and settings - user_profile_page.dart
library;

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config/constants.dart';
import '../../routes/app_router.dart';

/// User profile page
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});
  void _showSupportBottomSheet(BuildContext context) {
    // Helper function to handle launching URLs safely
    Future<void> launch(Uri url) async {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $url");
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "We're here for you! 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Got a question? Our team is just a click away.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // PHONE OPTION
                    ListTile(
                      leading: const Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: const Text(
                        "Give us a ring",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => launch(
                              Uri(scheme: 'tel', path: '+918073946496'),
                            ),
                            child: const Text(
                              "+91 8073 946 496",
                              style: TextStyle(color: Colors.blue, height: 1.5),
                            ),
                          ),
                          InkWell(
                            onTap: () => launch(
                              Uri(scheme: 'tel', path: '+91 78298 78297'),
                            ),
                            child: const Text(
                              "+91 78298 78297",
                              style: TextStyle(color: Colors.blue, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 60),

                    // EMAIL OPTION
                    ListTile(
                      leading: const Icon(
                        Icons.alternate_email_rounded,
                        color: Colors.orangeAccent,
                      ),
                      title: const Text(
                        "Drop an email",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      // We use a Column in the subtitle to stack the two clickable emails
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4), // Small spacing
                          InkWell(
                            onTap: () => launch(
                              Uri(
                                scheme: 'mailto',
                                path: 'dhyanbhandari200@gmail.com',
                                query: 'subject=Support Request',
                              ),
                            ),
                            child: const Text(
                              "dhyanbhandari200@gmail.com",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ), // Gap between the two emails
                          InkWell(
                            onTap: () => launch(
                              Uri(
                                scheme: 'mailto',
                                path: 'travellerstriibe@gmail.com',
                                query: 'subject=Support Request',
                              ),
                            ),
                            child: const Text(
                              "travellerstriibe@gmail.com",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 60),

                    // WEBSITE OPTION (The Cite/Site link)
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Got it, thanks!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final account = authProvider.account;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.userHome),
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(account),
            const SizedBox(height: 24),
            _buildAccountInfo(account),
            const SizedBox(height: 24),
            _buildRoleSwitcher(context, authProvider),
            const SizedBox(height: 24),
            _buildSettingsSection(context),
            const SizedBox(height: 24),
            _buildLogoutButton(context, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Account? account) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              account?.email.isNotEmpty == true
                  ? account!.email[0].toUpperCase()
                  : 'U',
              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          account?.email ?? 'User',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          account?.phone ?? '',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfo(Account? account) {
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
            'Account Information',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email_outlined, 'Email', account?.email ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_outlined, 'Phone', account?.phone ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.verified_user_outlined,
            'Account ID',
            account?.accountId ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.check_circle_outline,
            'Status',
            account?.status.name.toUpperCase() ?? 'ACTIVE',
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
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
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSwitcher(BuildContext context, AuthProvider authProvider) {
    final availableRoles = authProvider.availableRoles;
    final activeRole = authProvider.activeRole;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Role',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  activeRole.name.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Role options
          if (availableRoles.length > 1) ...[
            ...availableRoles.map(
              (role) => _buildRoleOption(
                context,
                authProvider,
                role,
                isActive: role == activeRole,
              ),
            ),
          ] else ...[
            // Only has User role - show option to become partner
            _buildBecomePartnerOption(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    AuthProvider authProvider,
    UserRole role, {
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isActive
              ? null
              : () {
                  authProvider.switchRole(role);
                  // Navigate to new role home
                  switch (role) {
                    case UserRole.partner:
                      context.go(AppRoutes.partnerDashboard);
                      break;
                    case UserRole.admin:
                      context.go(AppRoutes.adminDashboard);
                      break;
                    case UserRole.user:
                      context.go(AppRoutes.userHome);
                      break;
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getRoleIcon(role),
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRoleLabel(role),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getRoleDescription(role),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBecomePartnerOption(BuildContext context) {
    return Material(
      color: AppColors.partnerAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go(AppRoutes.partnerOnboarding),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.partnerAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store_outlined,
                color: AppColors.partnerAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a Partner',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Start accepting payments with discounts',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.partnerAccent,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push(AppRoutes.notification),
          ),
          Divider(height: 1, color: AppColors.border),
          _buildSettingsItem(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => _showSupportBottomSheet(context),
          ),
          Divider(height: 1, color: AppColors.border),
          _buildSettingsItem(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () => context.push(AppRoutes.about),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textHint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await authProvider.logout();
          if (context.mounted) {
            context.go(AppRoutes.login);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person_outline;
      case UserRole.partner:
        return Icons.store_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.partner:
        return 'Partner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Scan & pay with discounts';
      case UserRole.partner:
        return 'Manage your business';
      case UserRole.admin:
        return 'Platform management';
    }
  }
}
