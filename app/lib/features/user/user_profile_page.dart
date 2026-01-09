/// User profile page with account info and settings
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config/constants.dart';
import '../../features/auth/models/account.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_router.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

/// User profile page
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

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
            _buildProfileHeader(context, account),
            const SizedBox(height: 24),
            _buildAccountInfo(context, account),
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

  Widget _buildProfileHeader(BuildContext context, Account? account) {
    Widget? imageContent;
    if (account?.profilePicture != null &&
        account!.profilePicture!.isNotEmpty) {
      if (account.profilePicture!.startsWith('data:')) {
        try {
          final base64String = account.profilePicture!.split(',')[1];
          imageContent = Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(account),
          );
        } catch (_) {}
      } else {
        imageContent = Image.network(
          account.profilePicture!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(account),
        );
      }
    }

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 4),
                boxShadow: AppShadows.small,
              ),
              child: ClipOval(child: imageContent ?? _buildInitials(account)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: () => _handleImageUpdate(context, account),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          account?.name ?? 'User',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildInitials(Account? account) {
    return Center(
      child: Text(
        account?.name.isNotEmpty == true
            ? account!.name[0].toUpperCase()
            : (account?.email.isNotEmpty == true
                  ? account!.email[0].toUpperCase()
                  : 'U'),
        style: AppTextStyles.h1.copyWith(
          color: AppColors.primary,
          fontSize: 40,
        ),
      ),
    );
  }

  Future<void> _handleImageUpdate(
    BuildContext context,
    Account? account,
  ) async {
    if (account == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 70,
    );

    if (image != null && context.mounted) {
      try {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updating profile picture...')),
        );

        final authProvider = context.read<AuthProvider>();
        // Keep existing name/phone
        final success = await authProvider.updateProfile(
          name: account.name,
          phone: account.phone,
          avatar: base64Image,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Failed to update picture',
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildAccountInfo(BuildContext context, Account? account) {
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
              Expanded(
                child: Text(
                  'Account Information',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'Edit Information',
                onPressed: () {
                  if (account != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => _EditProfileSheet(account: account),
                    );
                  }
                },
              ),
            ],
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
            onTap: () {
              // TODO: Implement notifications settings
            },
          ),
          Divider(height: 1, color: AppColors.border),
          _buildSettingsItem(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {
              // TODO: Implement help
            },
          ),
          Divider(height: 1, color: AppColors.border),
          _buildSettingsItem(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () {
              // TODO: Show about dialog
            },
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

class _EditProfileSheet extends StatefulWidget {
  final Account account;

  const _EditProfileSheet({required this.account});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _completePhoneNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _completePhoneNumber = widget.account.phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional phone validation
    if (_completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _completePhoneNumber,
        avatar: null, // Avatar handled via camera icon
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Failed to update profile',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to separate Country Code if possible, otherwise default to IN
    String initialCountry = 'IN';
    String initialNumber = widget.account.phone;

    // Simple heuristic: if starts with +91, strip it.
    // Otherwise IntlPhoneField might get confused if we pass full number as initialValue with country code
    if (initialNumber.startsWith('+91')) {
      initialCountry = 'IN';
      initialNumber = initialNumber.substring(3);
    } else if (initialNumber.startsWith('+1')) {
      initialCountry = 'US';
      initialNumber = initialNumber.substring(2);
    }
    // Add more if needed, or rely on user to correct it.
    // Ideally we parse it with libphonenumber but that requires async or heavy lib.

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Information',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: FormValidators.required('Full Name'),
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderSide: BorderSide()),
                ),
                initialCountryCode: initialCountry,
                initialValue: initialNumber,
                onChanged: (phone) {
                  _completePhoneNumber = phone.completeNumber;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
