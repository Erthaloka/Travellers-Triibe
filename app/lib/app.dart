/// File: app.dart
/// Purpose: Main app widget with theme and routing setup
/// Context: Root widget of the application

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/auth/auth_provider.dart';
import 'routes/app_router.dart';

/// Main application widget
/// Uses StatefulWidget to ensure the router is created once
class TravellersTrribeApp extends StatefulWidget {
  const TravellersTrribeApp({super.key});

  @override
  State<TravellersTrribeApp> createState() => _TravellersTrribeAppState();
}

class _TravellersTrribeAppState extends State<TravellersTrribeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create router ONCE with the auth provider
    // The router's refreshListenable will handle auth state changes
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.router(authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for light theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Travellers Triibe',
      debugShowCheckedModeBanner: false,

      // Light theme
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // Routing - use the single router instance
      routerConfig: _router,
    );
  }
}
