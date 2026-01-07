/// File: main.dart
/// Purpose: Application entry point
/// Context: Initializes providers and starts the app
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// --- NEW FIREBASE IMPORTS ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// ----------------------------
import 'app.dart';
import 'core/storage/secure_storage.dart';
import 'core/network/api_client.dart';
import 'core/auth/auth_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // --- INITIALIZE FIREBASE ---
  // This connects your Flutter code to the Firebase project you selected
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ----------------------------

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize core services
  final secureStorage = SecureStorage();
  final apiClient = ApiClient(secureStorage: secureStorage);
  final authProvider = AuthProvider(
    secureStorage: secureStorage,
    apiClient: apiClient,
  );

  // Initialize auth state
  await authProvider.initialize();

  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        // Core providers
        Provider<SecureStorage>.value(value: secureStorage),
        Provider<ApiClient>.value(value: apiClient),

        // Auth provider (needs to be ChangeNotifierProvider for state updates)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const TravellersTrribeApp(),
    ),
  );
}
