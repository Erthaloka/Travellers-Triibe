/// App routing configuration with role-based guards
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../core/config/constants.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/welcome_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/auth/complete_profile_page.dart';
import '../features/user/user_home_page.dart';
import '../features/user/scan_page.dart';
import '../features/user/payment_preview_page.dart';
import '../features/user/payment_success_page.dart';
import '../features/user/orders_page.dart';
import '../features/user/order_detail_page.dart';
import '../features/user/savings_page.dart';
import '../features/user/user_profile_page.dart';
import '../features/partner/onboarding/partner_onboarding_page.dart';
import '../features/partner/partner_dashboard_page.dart';
import '../features/partner/generate_qr_page.dart';
import '../features/partner/partner_orders_page.dart';
import '../features/partner/partner_order_detail_page.dart';
import '../features/partner/partner_analytics_page.dart';
import '../features/partner/partner_profile_page.dart';

/// Route paths
class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String roleSelection = '/role-selection';
  static const String signup = '/signup';
  static const String completeProfile = '/complete-profile';

  // User routes
  static const String userHome = '/user';
  static const String scan = '/user/scan';
  static const String paymentPreview = '/user/payment-preview';
  static const String paymentSuccess = '/user/payment-success';
  static const String userOrders = '/user/orders';
  static const String userOrderDetail = '/user/orders/:orderId';
  static const String userProfile = '/user/profile';
  static const String userSavings = '/user/savings';

  // Partner routes
  static const String partnerOnboarding = '/partner/onboarding';
  static const String partnerDashboard = '/partner';
  static const String generateQr = '/partner/generate-qr';
  static const String partnerOrders = '/partner/orders';
  static const String partnerOrderDetail = '/partner/orders/:orderId';
  static const String partnerAnalytics = '/partner/analytics';
  static const String partnerProfile = '/partner/profile';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminMerchants = '/admin/merchants';
  static const String adminMerchantDetail = '/admin/merchants/:merchantId';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminSettlements = '/admin/settlements';
}

/// App router configuration
class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(authProvider, state),
      routes: _routes,
      errorBuilder: (context, state) => _ErrorPage(error: state.error),
    );
  }

  /// Route redirect logic
  static String? _redirect(AuthProvider auth, GoRouterState state) {
    final isAuthenticated = auth.isAuthenticated;
    final isLoading =
        auth.state == AuthState.initial || auth.state == AuthState.loading;
    final currentPath = state.matchedLocation;

    // Auth flow paths that unauthenticated users can access
    final authPaths = [AppRoutes.welcome, AppRoutes.login, AppRoutes.signup];

    // While loading, stay where you are (don't redirect during active login)
    if (isLoading) {
      // If on auth pages, stay there (user is actively logging in)
      if (authPaths.contains(currentPath)) {
        return null;
      }
      // Otherwise, go to splash to wait for auth check
      return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
    }

    // If not authenticated, redirect to welcome (unless already on auth flow)
    if (!isAuthenticated) {
      if (currentPath == AppRoutes.splash) {
        return AppRoutes.welcome;
      }
      if (authPaths.contains(currentPath)) {
        return null; // Allow access to auth pages
      }
      return AppRoutes.welcome;
    }

    // Check if profile is complete (phone number existence)
    if (!auth.isProfileComplete) {
      // Allow staying on complete profile page
      if (currentPath == AppRoutes.completeProfile) {
        return null;
      }
      // Redirect to complete profile page
      return AppRoutes.completeProfile;
    } else {
      // If profile IS complete, but user tries to go back to complete profile manually
      if (currentPath == AppRoutes.completeProfile) {
        return _getHomeForRole(auth.activeRole);
      }
    }

    // If authenticated but on splash or auth pages, redirect to home based on role
    if (currentPath == AppRoutes.splash || authPaths.contains(currentPath)) {
      return _getHomeForRole(auth.activeRole);
    }

    // Role-based access control
    if (currentPath.startsWith('/partner') && !auth.hasRole(UserRole.partner)) {
      // User trying to access partner routes without partner role
      if (currentPath == AppRoutes.partnerOnboarding) {
        return null; // Allow onboarding
      }
      return AppRoutes.userHome;
    }

    if (currentPath.startsWith('/admin') && !auth.hasRole(UserRole.admin)) {
      return _getHomeForRole(auth.activeRole);
    }

    return null;
  }

  /// Get home route for role
  static String _getHomeForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppRoutes.adminDashboard;
      case UserRole.partner:
        return AppRoutes.partnerDashboard;
      case UserRole.user:
        return AppRoutes.userHome;
    }
  }

  /// Route definitions
  static final List<RouteBase> _routes = [
    // Splash route
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const _SplashPage(),
    ),

    // Welcome route
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),

    // Login route
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    // Signup route
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final role = extra?['role'] as String? ?? 'user';
        return SignupPage(role: role);
      },
    ),

    // Complete Profile route
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (context, state) => const CompleteProfilePage(),
    ),

    // User routes
    GoRoute(
      path: AppRoutes.userHome,
      builder: (context, state) => const UserHomePage(),
      routes: [
        GoRoute(path: 'scan', builder: (context, state) => const ScanPage()),
        GoRoute(
          path: 'payment-preview',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra == null) {
              return const _PlaceholderPage(title: 'Invalid Payment');
            }
            return PaymentPreviewPage(data: PaymentPreviewData.fromMap(extra));
          },
        ),
        GoRoute(
          path: 'payment-success',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            if (extra == null) {
              return const _PlaceholderPage(title: 'Invalid Payment');
            }
            return PaymentSuccessPage(data: PaymentSuccessData.fromMap(extra));
          },
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const UserOrdersPage(),
        ),
        GoRoute(
          path: 'orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return UserOrderDetailPage(orderId: orderId);
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const UserProfilePage(),
        ),
        GoRoute(
          path: 'savings',
          builder: (context, state) => const UserSavingsPage(),
        ),
      ],
    ),

    // Partner routes
    GoRoute(
      path: AppRoutes.partnerOnboarding,
      builder: (context, state) => const PartnerOnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.partnerDashboard,
      builder: (context, state) => const PartnerDashboardPage(),
      routes: [
        GoRoute(
          path: 'generate-qr',
          builder: (context, state) => const GenerateQrPage(),
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const PartnerOrdersPage(),
        ),
        GoRoute(
          path: 'orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return PartnerOrderDetailPage(orderId: orderId);
          },
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) => const PartnerAnalyticsPage(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const PartnerProfilePage(),
        ),
      ],
    ),

    // Admin routes
    GoRoute(
      path: AppRoutes.adminDashboard,
      builder: (context, state) =>
          const _PlaceholderPage(title: 'Admin Dashboard'),
      routes: [
        GoRoute(
          path: 'merchants',
          builder: (context, state) =>
              const _PlaceholderPage(title: 'Merchants'),
        ),
        GoRoute(
          path: 'merchants/:merchantId',
          builder: (context, state) {
            final merchantId = state.pathParameters['merchantId'] ?? '';
            return _PlaceholderPage(title: 'Merchant $merchantId');
          },
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const _PlaceholderPage(title: 'Users'),
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) =>
              const _PlaceholderPage(title: 'All Orders'),
        ),
        GoRoute(
          path: 'settlements',
          builder: (context, state) =>
              const _PlaceholderPage(title: 'Settlements'),
        ),
      ],
    ),
  ];
}

/// Splash page - shown during initialization
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.payments_outlined,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Travellers Triibe',
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Save instantly with every payment',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder page for routes not yet implemented
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error page
class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Page Not Found',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error?.toString() ??
                      'The page you are looking for does not exist.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.userHome),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
