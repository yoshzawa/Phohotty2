import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'pages/auth_page.dart';

void main() {
  // Use runZonedGuarded to catch any errors that are not caught by Flutter.
  runZonedGuarded<Future<void>>(
    initializeAndRunApp,
    (error, stack) {
      // This is a top-level error handler.
      // Ensure we can report the error to Crashlytics if initialized.
      if (Firebase.apps.isNotEmpty && FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

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
        rethrow;
      }
    }

    // --- DotEnv Initialization ---
    await dotenv.load(fileName: ".env");

    // --- Crashlytics Configuration ---
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // --- Photo Manager Initialization ---
    await PhotoManager.requestPermissionExtend();

    // --- Run Main App ---
    runApp(const MyApp()); // Run the main app widget which contains MaterialApp

  } catch (e, s) {
    // --- Run Error App ---
    final errorMessage = e.toString();
    if (Firebase.apps.isNotEmpty && FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'App initialization failed');
    } else {
      debugPrint('Initialization error: $e');
    }
    runApp(InitializationErrorScreen(error: errorMessage, onRetry: initializeAndRunApp));
  }
}

// The root widget of the application, providing MaterialApp.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phohotty',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthPage(), // AuthPage will handle UI based on auth state
    );
  }
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
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (e) {
        // In case accessing currentUser throws (e.g., during plugin registration issues)
        debugPrint('Could not retrieve current user: $e');
      }
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
