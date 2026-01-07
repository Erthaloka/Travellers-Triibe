/// Welcome/Landing page - Profile selection + Direct Login
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config/constants.dart';
import '../../routes/app_router.dart';

/// Welcome page with profile selection and direct login
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedProfile; // 'user' or 'partner'
  String? _errorMessage;
  bool _showCreateAccountPrompt = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_selectedProfile == null) {
      setState(() {
        _errorMessage = 'Please select a profile type first';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showCreateAccountPrompt = false;
    });

    final authProvider = context.read<AuthProvider>();
    authProvider.setSignupRole(_selectedProfile!);

    final success = await authProvider.loginWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate based on active role after router settles
      final role = authProvider.activeRole;
      Future.microtask(() {
        if (!mounted) return;
        if (role == UserRole.partner) {
          context.go(AppRoutes.partnerDashboard);
        } else if (role == UserRole.admin) {
          context.go(AppRoutes.adminDashboard);
        } else {
          context.go(AppRoutes.userHome);
        }
      });
    } else {
      // Check if error suggests account doesn't exist
      final error = authProvider.errorMessage ?? 'Login failed';
      if (error.toLowerCase().contains('not found') ||
          error.toLowerCase().contains('invalid') ||
          error.toLowerCase().contains('no account')) {
        setState(() {
          _showCreateAccountPrompt = true;
          _errorMessage = 'Account not found. Please create an account first.';
        });
      } else {
        setState(() {
          _errorMessage = error;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_selectedProfile == null) {
      setState(() {
        _errorMessage = 'Please select a profile type first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showCreateAccountPrompt = false;
    });

    final authProvider = context.read<AuthProvider>();
    authProvider.setSignupRole(_selectedProfile!);

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      final role = authProvider.activeRole;
      Future.microtask(() {
        if (!mounted) return;
        if (role == UserRole.partner) {
          context.go(AppRoutes.partnerDashboard);
        } else if (role == UserRole.admin) {
          context.go(AppRoutes.adminDashboard);
        } else {
          context.go(AppRoutes.userHome);
        }
      });
    } else if (authProvider.errorMessage != null) {
      setState(() {
        _errorMessage = authProvider.errorMessage;
      });
    }
  }

  void navigateToHome() {
    final authProvider = context.read<AuthProvider>();
    if (_selectedProfile == 'partner') {
      // Check if user needs onboarding
      if (authProvider.hasRole(UserRole.partner)) {
        context.go(AppRoutes.partnerDashboard);
      } else {
        context.go(AppRoutes.partnerOnboarding);
      }
    } else {
      context.go(AppRoutes.userHome);
    }
  }

  void _navigateToSignup() {
    if (_selectedProfile == null) {
      setState(() {
        _errorMessage = 'Please select a profile type first';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.setSignupRole(_selectedProfile!);
    context.push(AppRoutes.signup, extra: {'role': _selectedProfile});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildLogo(),
                const SizedBox(height: 24),
                _buildProfileSelection(),
                const SizedBox(height: 24),
                if (_selectedProfile != null) ...[_buildLoginSection()],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.payments_outlined,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Travellers Triibe',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Save on Every Payment',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProfileCard(
                role: 'user',
                icon: Icons.person_outline,
                title: 'Customer',
                subtitle: 'Pay & save at stores',
                color: AppColors.userAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProfileCard(
                role: 'partner',
                icon: Icons.store_outlined,
                title: 'Business',
                subtitle: 'Accept payments',
                color: AppColors.partnerAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedProfile == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProfile = role;
          _errorMessage = null;
          _showCreateAccountPrompt = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginSection() {
    final accentColor = _selectedProfile == 'partner'
        ? AppColors.partnerAccent
        : AppColors.userAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Login header
        Text(
          'Login',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),

        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: FormValidators.email,
        ),
        const SizedBox(height: 12),

        // Password field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Login button
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: accentColor),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Login'),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(accentColor),
        ],

        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        // Google Sign-In button
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Image.network(
            'https://www.google.com/favicon.ico',
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.g_mobiledata, size: 24),
          ),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Sign up link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _navigateToSignup,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: accentColor,
              ),
              child: const Text('Sign up'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _showCreateAccountPrompt
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _showCreateAccountPrompt
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _showCreateAccountPrompt
                    ? Icons.info_outline
                    : Icons.error_outline,
                color: _showCreateAccountPrompt
                    ? AppColors.warning
                    : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _showCreateAccountPrompt
                        ? AppColors.warning
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (_showCreateAccountPrompt) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _navigateToSignup,
                style: TextButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Create Account'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
