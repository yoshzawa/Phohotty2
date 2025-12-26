
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

    // Initialize Firebase (once)
    // if (Firebase.apps.isEmpty) {
    //   await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform,
    //   );
    // }

    // Setup Crashlytics handlers
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Request necessary permissions
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      throw Exception('Photo library permission not granted');
    }

    // --- Run Main App ---
    runApp(const MyApp());

  } catch (e, s) {
    // --- Run Error App ---
    // If initialization fails, record the error and show an error screen.
    // We check if Firebase is available before trying to use Crashlytics.
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'App initialization failed');
    } else {
      debugPrint('Firebase not available. Could not report initialization error to Crashlytics.');
      debugPrint(e.toString());
    }
    runApp(InitializationErrorScreen(onRetry: initializeAndRunApp));
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

// A screen to display when initialization fails, with a retry mechanism.
class InitializationErrorScreen extends StatelessWidget {
  final Future<void> Function() onRetry;
  const InitializationErrorScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 20),
              const Text('Application failed to start.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<FbUser?>(
        stream: FbAuth.instance.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            // Log auth-related errors to Crashlytics as well.
            FirebaseCrashlytics.instance.recordError(
              snapshot.error, 
              snapshot.stackTrace, 
              reason: 'Authentication State Stream Error'
            );
            return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
          }
          // If user data exists, they are logged in.
          return snapshot.hasData ? const MainTabPage() : const AuthPage();
        },
      ),
    );
  }
}
