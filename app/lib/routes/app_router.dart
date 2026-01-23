/// App routing configuration with role-based guards - app_router.dart
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_provider.dart';
import '../core/config/constants.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/welcome_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
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
import '../features/user/about.dart';
import '../features/user/user_notification.dart';

/// Route paths
class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';

  // User routes
  static const String userHome = '/user';
  static const String scan = '/user/scan';
  static const String paymentPreview = '/user/payment-preview';
  static const String paymentSuccess = '/user/payment-success';
  static const String userOrders = '/user/orders';
  static const String userOrderDetail = '/user/orders/:orderId';
  static const String userProfile = '/user/profile';
  static const String userSavings = '/user/savings';
  static const String about = '/about';
  static const String notification =
      '/user/notification'; // Fixed variable name

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

  static String? _redirect(AuthProvider auth, GoRouterState state) {
    final isAuthenticated = auth.isAuthenticated;
    final isLoading =
        auth.state == AuthState.initial || auth.state == AuthState.loading;
    final currentPath = state.matchedLocation;
    final authPaths = [AppRoutes.welcome, AppRoutes.login, AppRoutes.signup];

    if (isLoading) {
      return authPaths.contains(currentPath) ? null : AppRoutes.splash;
    }

    if (!isAuthenticated) {
      if (currentPath == AppRoutes.splash || !authPaths.contains(currentPath)) {
        return AppRoutes.welcome;
      }
      return null;
    }

    if (currentPath == AppRoutes.splash || authPaths.contains(currentPath)) {
      return _getHomeForRole(auth.activeRole);
    }

    if (currentPath.startsWith('/partner') && !auth.hasRole(UserRole.partner)) {
      return currentPath == AppRoutes.partnerOnboarding
          ? null
          : AppRoutes.userHome;
    }

    return null;
  }

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

  static final List<RouteBase> _routes = [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const _SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SignupPage(role: extra?['role'] ?? 'user');
      },
    ),

    // --- USER ROUTES ---
    GoRoute(
      path: AppRoutes.userHome,
      builder: (context, state) => const UserHomePage(),
      routes: [
        GoRoute(path: 'scan', builder: (context, state) => const ScanPage()),
        GoRoute(
          path: 'notification',
          builder: (context, state) => const UserNotificationsPage(),
        ),
        GoRoute(
          path: 'payment-preview',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentPreviewPage(
              data: PaymentPreviewData.fromMap(extra ?? {}),
            );
          },
        ),
        GoRoute(
          path: 'payment-success',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentSuccessPage(
              data: PaymentSuccessData.fromMap(extra ?? {}),
            );
          },
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => const UserOrdersPage(),
        ),
        GoRoute(
          path: 'orders/:orderId',
          builder: (context, state) => UserOrderDetailPage(
            orderId: state.pathParameters['orderId'] ?? '',
          ),
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

    // --- ABOUT ROUTE (Top Level) ---
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutPage(),
    ),

    // --- PARTNER ROUTES ---
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
          builder: (context, state) => PartnerOrderDetailPage(
            orderId: state.pathParameters['orderId'] ?? '',
          ),
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
  ];
}
// ... Rest of your _SplashPage and _ErrorPage code

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
