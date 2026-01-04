import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'pages/auth_page.dart';

// Wrapped the initialization and app run logic in a function to support retries.
Future<void> initializeAndRunApp() async {
  try {
    // --- Centralized Initialization ---
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase idempotently. This can be called multiple times safely.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        // Rethrow if it's not a duplicate app error.
        rethrow;
      }
      // If it's a duplicate app error, it means Firebase is already initialized, so we can safely continue.
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
    runApp(const AuthPage());

  } catch (e, s) {
    // --- Run Error App ---
    // If initialization fails, record the error and show an error screen with details.
    final errorMessage = e.toString();
    // Try to report to Crashlytics, but check if Firebase is available first.
    if (Firebase.apps.isNotEmpty && FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
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
      if (Firebase.apps.isNotEmpty && FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

// Enhanced error screen with diagnostic information.
class InitializationErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const InitializationErrorScreen({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // --- Check current states for diagnostics ---
    final isFirebaseInitialized = Firebase.apps.isNotEmpty;
    User? currentUser;
    if (isFirebaseInitialized) {
      currentUser = FirebaseAuth.instance.currentUser;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
                  'エラー詳細: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  onPressed: onRetry,
                ),

                // --- Diagnostic Info Section ---
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '現在の状態 (デバッグ用)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFirebaseInitialized ? Icons.check_circle : Icons.cancel,
                      color: isFirebaseInitialized ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('Firebase 初期化: ${isFirebaseInitialized ? "完了" : "未完了"}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      currentUser != null ? Icons.person_rounded : Icons.person_off_outlined,
                      color: currentUser != null ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('サインイン状態: ${currentUser != null ? "サインイン済み" : "未サインイン"}'),
                  ],
                ),
                if (currentUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '(ユーザー: ${currentUser.email ?? currentUser.uid})',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
