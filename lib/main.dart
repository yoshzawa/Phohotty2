import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'pages/main_tab_page.dart';
import 'pages/auth_page.dart';
import 'services/fb_auth.dart';

// Wrapped the initialization and app run logic in a function to support retries.
Future<void> initializeAndRunApp() async {
  try {
    // --- Centralized Initialization ---
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase (once) by checking if any apps are already initialized.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // --- DotEnv Initialization ---
    await dotenv.load(fileName: ".env");

    // --- Crashlytics Configuration ---
    // Pass all uncaught "fatal" errors from the framework to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // --- Photo Manager Initialization ---
    // Pre-request permissions for the photo manager to avoid delays later.
    await PhotoManager.requestPermissionExtend();

    // --- Run Main App ---
    runApp(const AuthGate());

  } catch (e, s) {
    // --- Run Error App ---
    // If initialization fails, record the error and show an error screen with details.
    final errorMessage = e.toString();
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'App initialization failed');
    } else {
      debugPrint('Firebase not available. Could not report initialization error to Crashlytics.');
      debugPrint(errorMessage);
    }
    runApp(InitializationErrorScreen(error: errorMessage, onRetry: initializeAndRunApp));
  }
}

void main() {
  // Use runZonedGuarded to catch any errors that are not caught by Flutter.
  runZonedGuarded<Future<void>>(
    initializeAndRunApp,
    (error, stack) {
      // This is a top-level error handler.
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

// Stateless widget to show when initialization fails, now with error details.
class InitializationErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const InitializationErrorScreen({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'アプリの起動に失敗しました',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '詳細: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
