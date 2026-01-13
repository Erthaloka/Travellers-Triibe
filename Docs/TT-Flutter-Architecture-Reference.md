# TRAVELLERS TRIIBE - FLUTTER ARCHITECTURE REFERENCE

**Research-Based Patterns from Open Source Flutter Apps**

---

# TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [Studied Open Source Apps](#2-studied-open-source-apps)
3. [Recommended Architecture Pattern](#3-recommended-architecture-pattern)
4. [Project Structure](#4-project-structure)
5. [State Management Strategy](#5-state-management-strategy)
6. [Package Recommendations](#6-package-recommendations)
7. [Authentication & Role Management](#7-authentication--role-management)
8. [QR Code Implementation](#8-qr-code-implementation)
9. [Payment Integration (Razorpay)](#9-payment-integration-razorpay)
10. [Offline-First & Caching](#10-offline-first--caching)
11. [Navigation & Routing](#11-navigation--routing)
12. [UI Component Patterns](#12-ui-component-patterns)
13. [API Client Architecture](#13-api-client-architecture)
14. [Error Handling Patterns](#14-error-handling-patterns)
15. [Testing Strategy](#15-testing-strategy)
16. [Build & Release](#16-build--release)

---

# 1. EXECUTIVE SUMMARY

## Research Sources

| App | What We Learned |
|-----|-----------------|
| **Invoice Ninja** | Redux-based architecture, modular folder structure, admin portal patterns |
| **Flutter POS System** | Offline-first design, order management, privacy-focused local storage |
| **MPoS** | Firebase + Supabase integration, ObjectBox local DB, transaction handling |

## Key Decisions for Travellers Triibe

Based on research and your PRD requirements:

| Aspect | Decision | Reasoning |
|--------|----------|-----------|
| Architecture | **Clean Architecture (Simplified)** | Matches PRD's feature-first approach |
| State Management | **Provider** | PRD specifies it, simple for MVP, officially recommended |
| Local DB | **SQLite (sqflite)** | PRD specifies it for UX cache |
| Navigation | **go_router** | Role-based routing, deep linking support |
| QR Scanner | **mobile_scanner** | Modern, well-maintained, better than deprecated packages |
| Payments | **razorpay_flutter** | PRD requirement |

---

# 2. STUDIED OPEN SOURCE APPS

## 2.1 Invoice Ninja Admin Portal

**Repository:** https://github.com/invoiceninja/admin-portal

### Architecture Pattern
```
Redux-based State Management
├── data/          → Models, repositories, data sources
├── redux/         → Actions, reducers, middleware, state
├── ui/            → Views, widgets, screens
└── utils/         → Helpers, formatters
```

### Key Learnings

**What to Adopt:**
- Separation of data, state, and UI layers
- Modular feature organization
- Centralized color and constant definitions
- Environment configuration pattern (.env.dart)

**What to Skip:**
- Redux (overkill for MVP, PRD specifies Provider)
- Complex dependency chains
- Heavy package count (100+ packages)

### Useful Patterns from Invoice Ninja

```dart
// Color centralization pattern
// colors.dart
class AppColors {
  static const userPrimary = Color(0xFF2196F3);
  static const partnerPrimary = Color(0xFF4CAF50);
  static const adminPrimary = Color(0xFF9C27B0);
}

// Environment config pattern
// env.dart
class Env {
  static const apiBaseUrl = String.fromEnvironment('API_URL');
  static const razorpayKey = String.fromEnvironment('RAZORPAY_KEY');
}
```

---

## 2.2 Flutter POS System

**Repository:** https://github.com/evan361425/flutter-pos-system

### Architecture Pattern
```
Feature-Based + Offline-First
├── Full offline functionality
├── Local-only data storage (privacy-first)
├── Responsive adaptive UI
└── Export/backup capabilities
```

### Key Learnings

**What to Adopt:**
- Offline-first mindset (aligns with your SQLite caching strategy)
- Privacy-first approach (no remote personal data)
- Responsive design patterns
- Export functionality for orders

**Relevant Packages:**
- `syncfusion_flutter_charts` - For analytics/charts
- `csv` - Export functionality
- `pdf` / `printing` - Receipt generation
- `connectivity_plus` - Network detection

### Useful Patterns from POS System

```dart
// Offline-first data flow
class OrderRepository {
  final LocalDatabase _localDb;
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;

  Future<List<Order>> getOrders() async {
    // Always return local first for speed
    final localOrders = await _localDb.getOrders();

    if (await _connectivity.isOnline) {
      // Sync in background
      _syncWithServer();
    }

    return localOrders;
  }
}
```

---

## 2.3 MPoS Flutter

**Repository:** https://github.com/kiks12/mpos-flutter

### Architecture Pattern
```
Backend-as-a-Service (BaaS)
├── Supabase for backend
├── Firebase for auth
├── ObjectBox for local storage
└── GetStorage for preferences
```

### Key Learnings

**What to Adopt:**
- Clean separation between auth (Firebase) and data (Supabase)
- ObjectBox pattern for local caching (similar to SQLite approach)
- Permission handling patterns
- Toast notifications for user feedback

**What to Skip:**
- Multiple BaaS dependencies (you have custom Node.js backend)
- ObjectBox (stick with SQLite per PRD)

### Useful Patterns from MPoS

```dart
// Permission handling pattern
class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> checkAndRequestPermissions() async {
    final camera = await requestCameraPermission();
    if (!camera) {
      // Show settings dialog
      await openAppSettings();
      return false;
    }
    return true;
  }
}
```

---

# 3. RECOMMENDED ARCHITECTURE PATTERN

## 3.1 Clean Architecture (Simplified for MVP)

Based on research and 2025 best practices, use a **simplified Clean Architecture**:

```
┌─────────────────────────────────────────────────────┐
│                   PRESENTATION                       │
│         (UI Widgets, Pages, Providers)              │
├─────────────────────────────────────────────────────┤
│                     DOMAIN                           │
│         (Services, Business Logic)                  │
├─────────────────────────────────────────────────────┤
│                      DATA                            │
│    (Repositories, API Client, Local Storage)        │
└─────────────────────────────────────────────────────┘
```

## 3.2 Dependency Flow

```
UI (Pages/Widgets)
      ↓ uses
  Providers (State)
      ↓ calls
  Services (Business Logic)
      ↓ uses
  Repositories (Data Access)
      ↓ talks to
  Data Sources (API / SQLite)
```

**Rule:** Dependencies flow downward only. Never upward.

---

# 4. PROJECT STRUCTURE

## 4.1 Recommended Folder Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp configuration
│
├── core/                              # Shared app-wide code
│   ├── config/
│   │   ├── env.dart                   # Environment variables
│   │   ├── constants.dart             # App constants
│   │   └── theme/
│   │       ├── app_theme.dart         # Theme configuration
│   │       ├── user_theme.dart        # User role colors
│   │       ├── partner_theme.dart     # Partner role colors
│   │       └── admin_theme.dart       # Admin role colors
│   │
│   ├── network/
│   │   ├── api_client.dart            # HTTP client wrapper
│   │   ├── api_endpoints.dart         # API endpoint constants
│   │   ├── api_interceptors.dart      # Auth, logging interceptors
│   │   └── api_exceptions.dart        # Custom exceptions
│   │
│   ├── storage/
│   │   ├── secure_storage.dart        # JWT token storage
│   │   ├── local_cache.dart           # SQLite operations
│   │   └── preferences.dart           # SharedPreferences wrapper
│   │
│   ├── auth/
│   │   ├── auth_provider.dart         # Auth state management
│   │   ├── auth_service.dart          # Auth business logic
│   │   └── auth_guard.dart            # Route protection
│   │
│   ├── widgets/                       # Reusable widgets
│   │   ├── loading_overlay.dart
│   │   ├── error_view.dart
│   │   ├── role_switcher.dart
│   │   ├── amount_breakdown_card.dart
│   │   ├── order_list_item.dart
│   │   └── status_badge.dart
│   │
│   └── utils/
│       ├── formatters.dart            # Currency, date formatters
│       ├── validators.dart            # Input validation
│       └── text_normalizer.dart       # Unicode safety
│
├── features/                          # Feature modules
│   ├── auth/
│   │   ├── auth_context.md            # Feature documentation
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── otp_verification_page.dart
│   │   │   └── role_selection_page.dart
│   │   └── widgets/
│   │       └── login_form.dart
│   │
│   ├── user/
│   │   ├── user_context.md
│   │   ├── providers/
│   │   │   ├── user_provider.dart
│   │   │   └── savings_provider.dart
│   │   ├── services/
│   │   │   ├── user_service.dart
│   │   │   └── savings_service.dart
│   │   ├── pages/
│   │   │   ├── user_home_page.dart
│   │   │   ├── scan_page.dart
│   │   │   ├── payment_preview_page.dart
│   │   │   ├── payment_success_page.dart
│   │   │   ├── user_orders_page.dart
│   │   │   ├── user_order_detail_page.dart
│   │   │   ├── user_savings_page.dart
│   │   │   └── user_profile_page.dart
│   │   └── widgets/
│   │       ├── savings_card.dart
│   │       └── recent_merchants_list.dart
│   │
│   ├── partner/
│   │   ├── partner_context.md
│   │   ├── providers/
│   │   │   ├── partner_provider.dart
│   │   │   └── onboarding_provider.dart
│   │   ├── services/
│   │   │   ├── partner_service.dart
│   │   │   └── qr_service.dart
│   │   ├── pages/
│   │   │   ├── onboarding/
│   │   │   │   ├── business_details_page.dart
│   │   │   │   ├── gst_verification_page.dart
│   │   │   │   └── commercial_setup_page.dart
│   │   │   ├── partner_dashboard_page.dart
│   │   │   ├── generate_qr_page.dart
│   │   │   ├── partner_orders_page.dart
│   │   │   ├── partner_order_detail_page.dart
│   │   │   ├── partner_analytics_page.dart
│   │   │   └── partner_profile_page.dart
│   │   └── widgets/
│   │       ├── qr_display.dart
│   │       ├── bill_input.dart
│   │       └── dashboard_stats_card.dart
│   │
│   ├── admin/
│   │   ├── admin_context.md
│   │   ├── providers/
│   │   │   └── admin_provider.dart
│   │   ├── services/
│   │   │   ├── admin_service.dart
│   │   │   └── settlement_service.dart
│   │   ├── pages/
│   │   │   ├── admin_dashboard_page.dart
│   │   │   ├── merchants_page.dart
│   │   │   ├── admin_orders_page.dart
│   │   │   ├── settlements_page.dart
│   │   │   └── admin_users_page.dart
│   │   └── widgets/
│   │       └── merchant_list_item.dart
│   │
│   └── payment/
│       ├── payment_context.md
│       ├── providers/
│       │   └── payment_provider.dart
│       ├── services/
│       │   ├── payment_service.dart
│       │   └── razorpay_service.dart
│       └── widgets/
│           └── payment_method_selector.dart
│
├── models/                            # Data models
│   ├── account.dart
│   ├── user.dart
│   ├── merchant.dart
│   ├── order.dart
│   ├── payment.dart
│   └── settlement.dart
│
├── repositories/                      # Data access layer
│   ├── auth_repository.dart
│   ├── user_repository.dart
│   ├── merchant_repository.dart
│   ├── order_repository.dart
│   └── payment_repository.dart
│
└── routes/
    ├── app_router.dart                # Route definitions
    └── route_guards.dart              # Auth & role guards
```

---

## 4.2 Feature Context File Template

Every feature folder should have a `*_context.md` file:

```markdown
# User Feature Context

## Purpose
This module contains all screens and logic for end users (customer role).

## Responsibilities
- Scan QR and initiate payment
- View discount before payment
- View order history
- Track savings

## Does NOT Handle
- Merchant flows (partner module)
- Admin actions (admin module)
- Payment calculations (server-side only)

## Key APIs Used
- GET /user/home/recents
- GET /user/savings/summary
- GET /user/orders
- POST /payment/prepare

## State Management
- UserProvider: User profile and home data
- SavingsProvider: Savings calculations and history

## Local Cache
- Recent merchants (SQLite)
- NOT: Payment data, balances

## Dependencies
- core/auth (authentication state)
- core/network (API client)
- payment feature (payment flows)
```

---

# 5. STATE MANAGEMENT STRATEGY

## 5.1 Provider Architecture

Based on research and PRD requirements, use **Provider** with this pattern:

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│   (Widgets read state, call provider methods)       │
├─────────────────────────────────────────────────────┤
│                 Provider Layer                       │
│   (Holds state, notifies UI, calls services)        │
├─────────────────────────────────────────────────────┤
│                 Service Layer                        │
│   (Business logic, no UI knowledge)                 │
├─────────────────────────────────────────────────────┤
│               Repository Layer                       │
│   (Data access, API + Local DB)                     │
└─────────────────────────────────────────────────────┘
```

## 5.2 Provider Implementation Pattern

### Base Provider Class

```dart
/// lib/core/base/base_provider.dart

import 'package:flutter/foundation.dart';

enum ViewState { idle, loading, success, error }

abstract class BaseProvider extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
```

### Feature Provider Example

```dart
/// lib/features/payment/providers/payment_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/base/base_provider.dart';
import '../services/payment_service.dart';
import '../../../models/payment_preview.dart';

class PaymentProvider extends BaseProvider {
  final PaymentService _paymentService;

  PaymentProvider(this._paymentService);

  PaymentPreview? _preview;
  PaymentPreview? get preview => _preview;

  Future<void> preparePayment({
    required String merchantId,
    required double billAmount,
  }) async {
    setLoading();

    try {
      _preview = await _paymentService.preparePayment(
        merchantId: merchantId,
        billAmount: billAmount,
      );
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  void clearPreview() {
    _preview = null;
    setIdle();
  }
}
```

## 5.3 Provider Setup in main.dart

```dart
/// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),

        // Feature providers (lazy loaded)
        ChangeNotifierProvider(create: (_) => UserProvider(userService)),
        ChangeNotifierProvider(create: (_) => PartnerProvider(partnerService)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(paymentService)),
        ChangeNotifierProvider(create: (_) => AdminProvider(adminService)),
      ],
      child: const TravellersTriibeApp(),
    ),
  );
}
```

## 5.4 Using Providers in UI

```dart
/// Reading state (rebuilds on change)
final user = context.watch<UserProvider>();

/// Reading state (no rebuild)
final user = context.read<UserProvider>();

/// Calling methods
context.read<PaymentProvider>().preparePayment(
  merchantId: merchantId,
  billAmount: amount,
);

/// Selector for specific property (performance optimization)
final isLoading = context.select<PaymentProvider, bool>(
  (provider) => provider.isLoading,
);
```

---

# 6. PACKAGE RECOMMENDATIONS

## 6.1 Core Packages (Must Have)

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1

  # Navigation
  go_router: ^14.0.0

  # Network
  http: ^1.2.0
  # OR
  dio: ^5.4.0  # If you need interceptors

  # Local Storage
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0

  # QR Code
  mobile_scanner: ^5.0.0      # QR scanning
  qr_flutter: ^4.1.0          # QR generation

  # Payments
  razorpay_flutter: ^1.3.6

  # UI Utilities
  intl: ^0.19.0               # Date/currency formatting
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0             # Loading states
  fluttertoast: ^8.2.4        # Toast messages

  # Connectivity
  connectivity_plus: ^6.0.0

  # Permissions
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  json_serializable: ^6.7.0   # If using code generation
```

## 6.2 Packages NOT to Use (MVP)

```yaml
# AVOID these for MVP (add later if needed)

# Over-engineered state management
# - flutter_bloc (overkill for MVP)
# - riverpod (migration cost not worth it)
# - getx (magic, hard to debug)
# - redux (too complex)

# Heavy analytics
# - firebase_analytics
# - mixpanel_flutter
# - amplitude_flutter

# Heavy UI libraries
# - lottie (adds ~2MB)
# - flutter_animate (unnecessary)
# - any large icon packs

# Background services
# - workmanager
# - flutter_background_service
```

## 6.3 Package Comparison (Research-Based)

| Category | Recommended | Alternative | Avoid |
|----------|-------------|-------------|-------|
| State | provider | riverpod | getx, redux |
| HTTP | dio | http | chopper |
| Local DB | sqflite | drift | objectbox, hive |
| Navigation | go_router | auto_route | navigator 1.0 |
| QR Scan | mobile_scanner | qr_code_scanner | barcode_scan |
| Forms | flutter built-in | reactive_forms | flutter_form_builder |

---

# 7. AUTHENTICATION & ROLE MANAGEMENT

## 7.1 Auth Flow Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AuthProvider                      │
│  - currentAccount                                   │
│  - activeRole (USER | PARTNER | ADMIN)             │
│  - isAuthenticated                                  │
│  - token                                            │
├─────────────────────────────────────────────────────┤
│                    AuthService                       │
│  - login(email, phone, otp)                         │
│  - logout()                                         │
│  - refreshToken()                                   │
│  - switchRole(role)                                 │
├─────────────────────────────────────────────────────┤
│                  AuthRepository                      │
│  - API calls                                        │
│  - Token storage (secure)                           │
│  - Last role storage (preferences)                  │
└─────────────────────────────────────────────────────┘
```

## 7.2 Auth Provider Implementation

```dart
/// lib/core/auth/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../base/base_provider.dart';
import '../../models/account.dart';
import 'auth_service.dart';

enum UserRole { user, partner, admin }

class AuthProvider extends BaseProvider {
  final AuthService _authService;

  AuthProvider(this._authService);

  Account? _account;
  UserRole _activeRole = UserRole.user;
  String? _token;

  // Getters
  Account? get account => _account;
  UserRole get activeRole => _activeRole;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _account != null;

  List<UserRole> get availableRoles {
    if (_account == null) return [];
    return _account!.roles.map((r) => _stringToRole(r)).toList();
  }

  bool get canSwitchToPartner =>
      _account?.roles.contains('PARTNER') ?? false;

  bool get canSwitchToAdmin =>
      _account?.roles.contains('ADMIN') ?? false;

  // Actions
  Future<void> login({
    required String email,
    required String phone,
    required String otp,
  }) async {
    setLoading();
    try {
      final result = await _authService.login(
        email: email,
        phone: phone,
        otp: otp,
      );
      _token = result.token;
      _account = result.account;
      _activeRole = _determineInitialRole();
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _account = null;
    _activeRole = UserRole.user;
    setIdle();
  }

  void switchRole(UserRole role) {
    if (!availableRoles.contains(role)) return;
    _activeRole = role;
    _authService.saveLastActiveRole(role);
    notifyListeners();
  }

  Future<void> restoreSession() async {
    setLoading();
    try {
      final session = await _authService.getStoredSession();
      if (session != null) {
        _token = session.token;
        _account = session.account;
        _activeRole = await _authService.getLastActiveRole();
        setSuccess();
      } else {
        setIdle();
      }
    } catch (e) {
      setIdle();
    }
  }

  UserRole _determineInitialRole() {
    // Default to USER, unless only PARTNER exists
    if (_account!.roles.contains('USER')) return UserRole.user;
    if (_account!.roles.contains('PARTNER')) return UserRole.partner;
    return UserRole.admin;
  }

  UserRole _stringToRole(String role) {
    switch (role) {
      case 'PARTNER': return UserRole.partner;
      case 'ADMIN': return UserRole.admin;
      default: return UserRole.user;
    }
  }
}
```

## 7.3 Role-Based Theme Switching

```dart
/// lib/core/config/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../../../core/auth/auth_provider.dart';

class AppTheme {
  static ThemeData getThemeForRole(UserRole role) {
    switch (role) {
      case UserRole.user:
        return _userTheme;
      case UserRole.partner:
        return _partnerTheme;
      case UserRole.admin:
        return _adminTheme;
    }
  }

  // User: Calm, trust-focused (blues)
  static final _userTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2196F3),
      foregroundColor: Colors.white,
    ),
  );

  // Partner: Bold, growth-focused (greens)
  static final _partnerTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
    ),
  );

  // Admin: Serious, analytical (purples)
  static final _adminTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF673AB7),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF673AB7),
      foregroundColor: Colors.white,
    ),
  );
}
```

## 7.4 Role Switcher Widget

```dart
/// lib/core/widgets/role_switcher.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PopupMenuButton<UserRole>(
      initialValue: auth.activeRole,
      onSelected: (role) => auth.switchRole(role),
      itemBuilder: (context) => [
        if (auth.availableRoles.contains(UserRole.user))
          const PopupMenuItem(
            value: UserRole.user,
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('User Mode'),
              subtitle: Text('Scan & Pay'),
            ),
          ),
        if (auth.availableRoles.contains(UserRole.partner))
          const PopupMenuItem(
            value: UserRole.partner,
            child: ListTile(
              leading: Icon(Icons.store),
              title: Text('Partner Mode'),
              subtitle: Text('Manage Business'),
            ),
          ),
        if (auth.availableRoles.contains(UserRole.admin))
          const PopupMenuItem(
            value: UserRole.admin,
            child: ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text('Admin Mode'),
              subtitle: Text('Platform Control'),
            ),
          ),
      ],
      child: Chip(
        avatar: Icon(_getRoleIcon(auth.activeRole), size: 18),
        label: Text(_getRoleLabel(auth.activeRole)),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user: return Icons.person;
      case UserRole.partner: return Icons.store;
      case UserRole.admin: return Icons.admin_panel_settings;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.user: return 'User';
      case UserRole.partner: return 'Partner';
      case UserRole.admin: return 'Admin';
    }
  }
}
```

---

# 8. QR CODE IMPLEMENTATION

## 8.1 QR Scanner Service

```dart
/// lib/features/user/services/qr_scanner_service.dart

import 'dart:convert';

class QrPayload {
  final String billId;
  final String merchantId;
  final int expiresAt;

  QrPayload({
    required this.billId,
    required this.merchantId,
    required this.expiresAt,
  });

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAt * 1000;

  factory QrPayload.fromBase64(String encoded) {
    try {
      final decoded = utf8.decode(base64.decode(encoded));
      final json = jsonDecode(decoded);
      return QrPayload(
        billId: json['bill_id'],
        merchantId: json['merchant_id'],
        expiresAt: json['exp'],
      );
    } catch (e) {
      throw QrException('Invalid QR code format');
    }
  }
}

class QrException implements Exception {
  final String message;
  QrException(this.message);

  @override
  String toString() => message;
}
```

## 8.2 QR Scanner Page

```dart
/// lib/features/user/pages/scan_page.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/qr_scanner_service.dart';
import '../../payment/providers/payment_provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Pay'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onQrDetected,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at merchant QR code',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQrDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);

    try {
      final payload = QrPayload.fromBase64(barcode!.rawValue!);

      if (payload.isExpired) {
        _showError('QR code has expired. Ask merchant to regenerate.');
        return;
      }

      // Navigate to payment preview
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/payment/preview',
          arguments: {
            'billId': payload.billId,
            'merchantId': payload.merchantId,
          },
        );
      }
    } catch (e) {
      _showError('Invalid QR code. Please scan a valid merchant QR.');
    } finally {
      // Allow scanning again after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## 8.3 QR Code Generator (Partner Side)

```dart
/// lib/features/partner/widgets/qr_display.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplay extends StatefulWidget {
  final String qrToken;
  final DateTime expiresAt;
  final VoidCallback onExpired;

  const QrDisplay({
    super.key,
    required this.qrToken,
    required this.expiresAt,
    required this.onExpired,
  });

  @override
  State<QrDisplay> createState() => _QrDisplayState();
}

class _QrDisplayState extends State<QrDisplay> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = widget.expiresAt.difference(DateTime.now());
      });

      if (_remaining.isNegative) {
        timer.cancel();
        widget.onExpired();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining.isNegative;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: QrImageView(
            data: widget.qrToken,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            errorStateBuilder: (context, error) {
              return const Center(
                child: Text('Error generating QR'),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isExpired ? Colors.red : Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpired ? Icons.timer_off : Icons.timer,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isExpired
                    ? 'Expired'
                    : '${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),

        if (isExpired) ...[
          const SizedBox(height: 16),
          const Text(
            'QR code expired. Generate a new one.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
```

---

# 9. PAYMENT INTEGRATION (RAZORPAY)

## 9.1 Razorpay Service

```dart
/// lib/features/payment/services/razorpay_service.dart

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayConfig {
  final String orderId;
  final int amountInPaise;
  final String currency;
  final String merchantName;
  final String description;
  final String userEmail;
  final String userPhone;

  RazorpayConfig({
    required this.orderId,
    required this.amountInPaise,
    this.currency = 'INR',
    required this.merchantName,
    required this.description,
    required this.userEmail,
    required this.userPhone,
  });
}

class RazorpayService {
  late Razorpay _razorpay;

  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required RazorpayConfig config,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    final options = {
      'key': const String.fromEnvironment('RAZORPAY_KEY'),
      'amount': config.amountInPaise,
      'currency': config.currency,
      'name': config.merchantName,
      'description': config.description,
      'order_id': config.orderId,
      'prefill': {
        'email': config.userEmail,
        'contact': config.userPhone,
      },
      'theme': {
        'color': '#2196F3',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay error: $e');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  void dispose() {
    _razorpay.clear();
  }
}
```

## 9.2 Payment Provider

```dart
/// lib/features/payment/providers/payment_provider.dart

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/base/base_provider.dart';
import '../../../models/payment_preview.dart';
import '../services/payment_service.dart';
import '../services/razorpay_service.dart';

enum PaymentStatus { idle, preparing, ready, processing, success, failed }

class PaymentProvider extends BaseProvider {
  final PaymentService _paymentService;
  final RazorpayService _razorpayService;

  PaymentProvider(this._paymentService, this._razorpayService);

  PaymentPreview? _preview;
  PaymentStatus _paymentStatus = PaymentStatus.idle;
  String? _paymentId;
  String? _failureMessage;

  // Getters
  PaymentPreview? get preview => _preview;
  PaymentStatus get paymentStatus => _paymentStatus;
  String? get paymentId => _paymentId;
  String? get failureMessage => _failureMessage;
  bool get isPaymentReady => _paymentStatus == PaymentStatus.ready;

  // Prepare payment (fetch from backend)
  Future<void> preparePayment({
    required String merchantId,
    required double billAmount,
  }) async {
    _paymentStatus = PaymentStatus.preparing;
    notifyListeners();

    try {
      _preview = await _paymentService.preparePayment(
        merchantId: merchantId,
        billAmount: billAmount,
      );
      _paymentStatus = PaymentStatus.ready;
      notifyListeners();
    } catch (e) {
      _paymentStatus = PaymentStatus.failed;
      _failureMessage = e.toString();
      notifyListeners();
    }
  }

  // Initiate Razorpay checkout
  void initiatePayment({
    required String userEmail,
    required String userPhone,
  }) {
    if (_preview == null) return;

    _paymentStatus = PaymentStatus.processing;
    notifyListeners();

    _razorpayService.openCheckout(
      config: RazorpayConfig(
        orderId: _preview!.razorpayOrderId,
        amountInPaise: _preview!.netPayableInPaise,
        merchantName: _preview!.merchantName,
        description: 'Payment for ${_preview!.merchantName}',
        userEmail: userEmail,
        userPhone: userPhone,
      ),
      onSuccess: _onPaymentSuccess,
      onFailure: _onPaymentFailure,
    );
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    _paymentId = response.paymentId;
    _paymentStatus = PaymentStatus.success;
    notifyListeners();
  }

  void _onPaymentFailure(PaymentFailureResponse response) {
    _failureMessage = response.message ?? 'Payment failed';
    _paymentStatus = PaymentStatus.failed;
    notifyListeners();
  }

  void reset() {
    _preview = null;
    _paymentStatus = PaymentStatus.idle;
    _paymentId = null;
    _failureMessage = null;
    notifyListeners();
  }
}
```

## 9.3 Payment Preview Page (CRITICAL SCREEN)

```dart
/// lib/features/user/pages/payment_preview_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/amount_breakdown_card.dart';

class PaymentPreviewPage extends StatelessWidget {
  final String merchantId;
  final double billAmount;

  const PaymentPreviewPage({
    super.key,
    required this.merchantId,
    required this.billAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, payment, child) {
          if (payment.paymentStatus == PaymentStatus.preparing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (payment.paymentStatus == PaymentStatus.failed) {
            return _buildError(context, payment);
          }

          if (payment.preview == null) {
            return const Center(child: Text('Unable to load payment'));
          }

          return _buildContent(context, payment);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentProvider payment) {
    final preview = payment.preview!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Merchant Info
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.store, color: Colors.white),
              ),
              title: Text(
                preview.merchantName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Row(
                children: [
                  Text(preview.category),
                  if (preview.isGstVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                    const Text(' GST Verified',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Amount Breakdown (CRITICAL - shows discount BEFORE payment)
          AmountBreakdownCard(
            grossBill: preview.grossBill,
            discountPercent: preview.discountPercent,
            discountAmount: preview.discountAmount,
            netPayable: preview.netPayable,
          ),

          const SizedBox(height: 16),

          // Savings highlight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.savings, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Text(
                  'You save ₹${preview.discountAmount.toStringAsFixed(2)}!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Pay Button
          ElevatedButton(
            onPressed: payment.paymentStatus == PaymentStatus.processing
                ? null
                : () => _initiatePayment(context, payment),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: payment.paymentStatus == PaymentStatus.processing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pay ₹${preview.netPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Cancel Button
          TextButton(
            onPressed: () {
              payment.reset();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _initiatePayment(BuildContext context, PaymentProvider payment) {
    final auth = context.read<AuthProvider>();

    payment.initiatePayment(
      userEmail: auth.account?.email ?? '',
      userPhone: auth.account?.phone ?? '',
    );
  }

  Widget _buildError(BuildContext context, PaymentProvider payment) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(payment.failureMessage ?? 'Something went wrong'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              payment.preparePayment(
                merchantId: merchantId,
                billAmount: billAmount,
              );
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
```

---

# 10. OFFLINE-FIRST & CACHING

## 10.1 SQLite Local Cache

```dart
/// lib/core/storage/local_cache.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/merchant.dart';

class LocalCache {
  static Database? _database;
  static const String _dbName = 'travellers_triibe_cache.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Recent merchants table
    await db.execute('''
      CREATE TABLE recent_merchants (
        merchant_id TEXT PRIMARY KEY,
        merchant_name TEXT NOT NULL,
        category TEXT NOT NULL,
        last_order_at INTEGER NOT NULL,
        last_synced_at INTEGER NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_last_order ON recent_merchants(last_order_at DESC)
    ''');
  }

  // Recent Merchants CRUD

  Future<List<RecentMerchant>> getRecentMerchants({int limit = 10}) async {
    final db = await database;
    final results = await db.query(
      'recent_merchants',
      orderBy: 'last_order_at DESC',
      limit: limit,
    );

    return results.map((row) => RecentMerchant.fromMap(row)).toList();
  }

  Future<void> saveRecentMerchants(List<RecentMerchant> merchants) async {
    final db = await database;
    final batch = db.batch();

    for (final merchant in merchants) {
      batch.insert(
        'recent_merchants',
        merchant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> addRecentMerchant(RecentMerchant merchant) async {
    final db = await database;
    await db.insert(
      'recent_merchants',
      merchant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearRecentMerchants() async {
    final db = await database;
    await db.delete('recent_merchants');
  }

  Future<bool> isCacheStale({Duration maxAge = const Duration(minutes: 15)}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT MIN(last_synced_at) as oldest FROM recent_merchants
    ''');

    if (result.isEmpty || result.first['oldest'] == null) {
      return true;
    }

    final oldestSync = DateTime.fromMillisecondsSinceEpoch(
      result.first['oldest'] as int,
    );

    return DateTime.now().difference(oldestSync) > maxAge;
  }

  // Cleanup on logout
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('recent_merchants');
    // Add more tables as needed
  }
}

// Model for recent merchant
class RecentMerchant {
  final String merchantId;
  final String merchantName;
  final String category;
  final DateTime lastOrderAt;
  final DateTime lastSyncedAt;

  RecentMerchant({
    required this.merchantId,
    required this.merchantName,
    required this.category,
    required this.lastOrderAt,
    required this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() => {
    'merchant_id': merchantId,
    'merchant_name': merchantName,
    'category': category,
    'last_order_at': lastOrderAt.millisecondsSinceEpoch,
    'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
  };

  factory RecentMerchant.fromMap(Map<String, dynamic> map) => RecentMerchant(
    merchantId: map['merchant_id'],
    merchantName: map['merchant_name'],
    category: map['category'],
    lastOrderAt: DateTime.fromMillisecondsSinceEpoch(map['last_order_at']),
    lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(map['last_synced_at']),
  );
}
```

## 10.2 Cache Invalidation Strategy

```dart
/// lib/features/user/services/user_service.dart

class UserService {
  final ApiClient _apiClient;
  final LocalCache _localCache;

  UserService(this._apiClient, this._localCache);

  /// Get recent merchants with cache-first strategy
  Future<List<RecentMerchant>> getRecentMerchants({
    bool forceRefresh = false,
  }) async {
    // 1. Return cached data immediately
    final cached = await _localCache.getRecentMerchants();

    // 2. Check if we need to refresh
    final isStale = await _localCache.isCacheStale();

    if (!forceRefresh && !isStale && cached.isNotEmpty) {
      return cached;
    }

    // 3. Fetch from API
    try {
      final response = await _apiClient.get('/user/home/recents');
      final merchants = (response['recents'] as List)
          .map((m) => RecentMerchant(
                merchantId: m['merchant_id'],
                merchantName: m['merchant_name'],
                category: m['category'],
                lastOrderAt: DateTime.parse(m['last_order_at']),
                lastSyncedAt: DateTime.now(),
              ))
          .toList();

      // 4. Update cache
      await _localCache.saveRecentMerchants(merchants);

      return merchants;
    } catch (e) {
      // 5. Return cached on error
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Call after successful payment to invalidate cache
  Future<void> invalidateRecentsCache() async {
    await _localCache.clearRecentMerchants();
  }
}
```

---

# 11. NAVIGATION & ROUTING

## 11.1 Router Configuration

```dart
/// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/auth/auth_provider.dart';

// Import all pages...

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(context, state, authProvider),
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),

        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpVerificationPage(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionPage(),
        ),

        // User routes
        GoRoute(
          path: '/user',
          builder: (context, state) => const UserHomePage(),
          routes: [
            GoRoute(
              path: 'scan',
              builder: (context, state) => const ScanPage(),
            ),
            GoRoute(
              path: 'orders',
              builder: (context, state) => const UserOrdersPage(),
            ),
            GoRoute(
              path: 'orders/:orderId',
              builder: (context, state) => UserOrderDetailPage(
                orderId: state.pathParameters['orderId']!,
              ),
            ),
            GoRoute(
              path: 'savings',
              builder: (context, state) => const UserSavingsPage(),
            ),
            GoRoute(
              path: 'profile',
              builder: (context, state) => const UserProfilePage(),
            ),
          ],
        ),

        // Partner routes
        GoRoute(
          path: '/partner',
          builder: (context, state) => const PartnerDashboardPage(),
          routes: [
            GoRoute(
              path: 'onboarding',
              builder: (context, state) => const OnboardingPage(),
            ),
            GoRoute(
              path: 'generate-qr',
              builder: (context, state) => const GenerateQrPage(),
            ),
            GoRoute(
              path: 'orders',
              builder: (context, state) => const PartnerOrdersPage(),
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
          path: '/admin',
          builder: (context, state) => const AdminDashboardPage(),
          routes: [
            GoRoute(
              path: 'merchants',
              builder: (context, state) => const MerchantsPage(),
            ),
            GoRoute(
              path: 'orders',
              builder: (context, state) => const AdminOrdersPage(),
            ),
            GoRoute(
              path: 'settlements',
              builder: (context, state) => const SettlementsPage(),
            ),
            GoRoute(
              path: 'users',
              builder: (context, state) => const AdminUsersPage(),
            ),
          ],
        ),

        // Payment routes (accessible from user)
        GoRoute(
          path: '/payment/preview',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return PaymentPreviewPage(
              merchantId: args['merchantId'],
              billAmount: args['billAmount'],
            );
          },
        ),
        GoRoute(
          path: '/payment/success',
          builder: (context, state) => const PaymentSuccessPage(),
        ),
      ],
    );
  }

  static String? _redirect(
    BuildContext context,
    GoRouterState state,
    AuthProvider auth,
  ) {
    final isAuthenticated = auth.isAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/otp') ||
        state.matchedLocation == '/splash';

    // Not authenticated - redirect to login
    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    // Authenticated - redirect from auth routes to appropriate home
    if (isAuthenticated && isAuthRoute) {
      return _getHomeForRole(auth.activeRole);
    }

    // Role-based route protection
    if (isAuthenticated) {
      final path = state.matchedLocation;

      if (path.startsWith('/partner') && auth.activeRole != UserRole.partner) {
        return _getHomeForRole(auth.activeRole);
      }

      if (path.startsWith('/admin') && auth.activeRole != UserRole.admin) {
        return _getHomeForRole(auth.activeRole);
      }
    }

    return null;
  }

  static String _getHomeForRole(UserRole role) {
    switch (role) {
      case UserRole.user:
        return '/user';
      case UserRole.partner:
        return '/partner';
      case UserRole.admin:
        return '/admin';
    }
  }
}
```

---

# 12. UI COMPONENT PATTERNS

## 12.1 Amount Breakdown Card (Critical Component)

```dart
/// lib/core/widgets/amount_breakdown_card.dart

import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AmountBreakdownCard extends StatelessWidget {
  final double grossBill;
  final double discountPercent;
  final double discountAmount;
  final double netPayable;

  const AmountBreakdownCard({
    super.key,
    required this.grossBill,
    required this.discountPercent,
    required this.discountAmount,
    required this.netPayable,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),

            // Original Bill
            _buildRow(
              context,
              label: 'Bill Amount',
              value: Formatters.currency(grossBill),
            ),

            const SizedBox(height: 8),

            // Discount
            _buildRow(
              context,
              label: 'Discount (${discountPercent.toStringAsFixed(0)}%)',
              value: '- ${Formatters.currency(discountAmount)}',
              valueColor: Colors.green,
            ),

            const Divider(),

            // Net Payable
            _buildRow(
              context,
              label: 'You Pay',
              value: Formatters.currency(netPayable),
              isBold: true,
              valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: valueStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
```

## 12.2 Order List Item

```dart
/// lib/core/widgets/order_list_item.dart

import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../utils/formatters.dart';
import 'status_badge.dart';

class OrderListItem extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: _buildCategoryIcon(),
        title: Text(order.merchantName),
        subtitle: Text(Formatters.dateTime(order.createdAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.currency(order.netPaid),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData icon;
    Color color;

    switch (order.category) {
      case 'FOOD':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'STAY':
        icon = Icons.hotel;
        color = Colors.blue;
        break;
      case 'SERVICE':
        icon = Icons.build;
        color = Colors.purple;
        break;
      default:
        icon = Icons.shopping_bag;
        color = Colors.green;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }
}
```

## 12.3 Status Badge

```dart
/// lib/core/widgets/status_badge.dart

import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _StatusConfig _getConfig() {
    switch (status.toUpperCase()) {
      case 'PAID':
        return _StatusConfig(Colors.green, 'Paid');
      case 'PENDING':
        return _StatusConfig(Colors.orange, 'Pending');
      case 'FAILED':
        return _StatusConfig(Colors.red, 'Failed');
      case 'CREATED':
        return _StatusConfig(Colors.blue, 'Created');
      default:
        return _StatusConfig(Colors.grey, status);
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;
  _StatusConfig(this.color, this.label);
}
```

---

# 13. API CLIENT ARCHITECTURE

## 13.1 API Client with Interceptors

```dart
/// lib/core/network/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exceptions.dart';

class ApiClient {
  final http.Client _httpClient;
  final SecureStorage _secureStorage;

  ApiClient(this._httpClient, this._secureStorage);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final response = await _httpClient.get(
      Uri.parse('${ApiEndpoints.baseUrl}$path'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _httpClient.post(
      Uri.parse('${ApiEndpoints.baseUrl}$path'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _httpClient.put(
      Uri.parse('${ApiEndpoints.baseUrl}$path'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _httpClient.delete(
      Uri.parse('${ApiEndpoints.baseUrl}$path'),
      headers: await _getHeaders(),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Handle errors
    final errorMessage = body['error']?['message'] ?? 'Something went wrong';
    final errorCode = body['error']?['code'] ?? 'UNKNOWN';

    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 422:
        throw ValidationException(errorMessage, errorCode);
      default:
        throw ApiException(errorMessage, response.statusCode);
    }
  }
}
```

## 13.2 API Endpoints

```dart
/// lib/core/network/api_endpoints.dart

class ApiEndpoints {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.travellertriibe.com/api/v1',
  );

  // Auth
  static const login = '/auth/login';
  static const me = '/auth/me';

  // User
  static const userHome = '/user/home/recents';
  static const userSavings = '/user/savings/summary';
  static const userOrders = '/user/orders';
  static const userProfile = '/user/profile';

  // Payment
  static const qrValidate = '/qr/validate';
  static const paymentPrepare = '/payment/prepare';

  // Partner
  static const partnerOnboardingBusiness = '/partner/onboarding/business';
  static const partnerOnboardingGst = '/partner/onboarding/gst';
  static const partnerOnboardingCommercials = '/partner/onboarding/commercials';
  static const partnerDashboard = '/partner/dashboard';
  static const partnerBillCreate = '/partner/bill/create';
  static const partnerOrders = '/partner/orders';
  static const partnerAnalytics = '/partner/analytics';

  // Admin
  static const adminDashboard = '/admin/dashboard';
  static const adminMerchants = '/admin/merchants';
  static const adminOrders = '/admin/orders';
  static const adminSettlements = '/admin/settlements';
  static const adminUsers = '/admin/users';

  // Orders (shared)
  static String orderDetail(String orderId) => '/orders/$orderId';
}
```

---

# 14. ERROR HANDLING PATTERNS

## 14.1 Custom Exceptions

```dart
/// lib/core/network/api_exceptions.dart

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ValidationException extends ApiException {
  final String code;
  ValidationException(String message, this.code) : super(message, 422);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => message;
}
```

## 14.2 Error View Widget

```dart
/// lib/core/widgets/error_view.dart

import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

# 15. TESTING STRATEGY

## 15.1 Test Structure

```
test/
├── unit/
│   ├── services/
│   │   ├── payment_service_test.dart
│   │   └── user_service_test.dart
│   ├── providers/
│   │   ├── auth_provider_test.dart
│   │   └── payment_provider_test.dart
│   └── utils/
│       └── formatters_test.dart
│
├── widget/
│   ├── amount_breakdown_card_test.dart
│   └── order_list_item_test.dart
│
└── integration/
    ├── login_flow_test.dart
    └── payment_flow_test.dart
```

## 15.2 Provider Test Example

```dart
/// test/unit/providers/payment_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([PaymentService, RazorpayService])
void main() {
  late PaymentProvider provider;
  late MockPaymentService mockPaymentService;
  late MockRazorpayService mockRazorpayService;

  setUp(() {
    mockPaymentService = MockPaymentService();
    mockRazorpayService = MockRazorpayService();
    provider = PaymentProvider(mockPaymentService, mockRazorpayService);
  });

  group('preparePayment', () {
    test('should set loading state initially', () async {
      when(mockPaymentService.preparePayment(
        merchantId: anyNamed('merchantId'),
        billAmount: anyNamed('billAmount'),
      )).thenAnswer((_) async => mockPaymentPreview);

      provider.preparePayment(merchantId: 'm_123', billAmount: 500);

      expect(provider.paymentStatus, PaymentStatus.preparing);
    });

    test('should set ready state on success', () async {
      when(mockPaymentService.preparePayment(
        merchantId: anyNamed('merchantId'),
        billAmount: anyNamed('billAmount'),
      )).thenAnswer((_) async => mockPaymentPreview);

      await provider.preparePayment(merchantId: 'm_123', billAmount: 500);

      expect(provider.paymentStatus, PaymentStatus.ready);
      expect(provider.preview, isNotNull);
    });

    test('should set failed state on error', () async {
      when(mockPaymentService.preparePayment(
        merchantId: anyNamed('merchantId'),
        billAmount: anyNamed('billAmount'),
      )).thenThrow(Exception('Network error'));

      await provider.preparePayment(merchantId: 'm_123', billAmount: 500);

      expect(provider.paymentStatus, PaymentStatus.failed);
      expect(provider.failureMessage, isNotNull);
    });
  });
}
```

---

# 16. BUILD & RELEASE

## 16.1 Build Commands

```bash
# Development build
flutter run

# Release APK (split per ABI for smaller size)
flutter build apk --release --split-per-abi

# Release App Bundle (for Play Store)
flutter build appbundle --release

# iOS build
flutter build ios --release

# With environment variables
flutter run --dart-define=API_BASE_URL=https://api.dev.travellertriibe.com/api/v1 \
            --dart-define=RAZORPAY_KEY=rzp_test_xxxxx

# Production build
flutter build apk --release --split-per-abi \
            --dart-define=API_BASE_URL=https://api.travellertriibe.com/api/v1 \
            --dart-define=RAZORPAY_KEY=rzp_live_xxxxx
```

## 16.2 Expected APK Size

| Configuration | Expected Size |
|---------------|--------------|
| Debug APK | 80-100 MB |
| Release APK (arm64-v8a) | 15-20 MB |
| Release APK (armeabi-v7a) | 12-17 MB |
| Release APK (fat) | 25-35 MB |

Target: **< 30 MB** (per PRD)

---

# DOCUMENT END

**Version:** 1.0
**Created:** December 2024
**Purpose:** Architecture reference for Travellers Triibe Flutter app development

---

## Sources

- [Invoice Ninja Admin Portal](https://github.com/invoiceninja/admin-portal)
- [Flutter POS System](https://github.com/evan361425/flutter-pos-system)
- [MPoS Flutter](https://github.com/kiks12/mpos-flutter)
- [Flutter Provider State Management Guide](https://medium.com/@abhi.777665/flutter-provider-state-management-a-complete-guide-for-clean-architecture-25f0861b8a9b)
- [State Management Best Practices 2025](https://vibe-studio.ai/insights/state-management-in-flutter-best-practices-for-2025)
- [Razorpay Flutter Integration Guide](https://razorpay.com/docs/payments/payment-gateway/flutter-integration/standard/integration-steps/)
- [Flutter Clean Architecture Example](https://github.com/guilherme-v/flutter-clean-architecture-example)
