import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_tab_page.dart';
import 'pages/auth_page.dart';
import 'services/fb_auth.dart';

Future<void> main() async {
  // This top-level try-catch block is crucial for capturing any errors
  // during the app's startup sequence.
  try {
    // Ensure Flutter engine is initialized. This is a mandatory first step.
    WidgetsFlutterBinding.ensureInitialized();

    // The following are asynchronous initialization steps. An error in any
    // of these could prevent the app from starting.

    // 1. Load environment variables from a .env file.
    await dotenv.load(fileName: '.env');

    // 2. Initialize Firebase. This is a common point of failure if the
    //    platform-specific configuration files (e.g., GoogleService-Info.plist)
    //    are missing or incorrect.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Request necessary permissions (e.g., for photo access).
    await PhotoManager.requestPermissionExtend();

    // If all initializations succeed, run the main application.
    runApp(const MyApp());

  } catch (e, stackTrace) {
    // If any of the steps in the `try` block fail, this `catch` block will
    // execute. Instead of crashing or showing a white screen, we'll display
    // a dedicated error screen.
    debugPrint('FATAL: App initialization failed: $e');
    debugPrint(stackTrace.toString());
    runApp(InitializationErrorApp(error: e));
  }
}

// A new widget to display when a fatal initialization error occurs.
// This prevents the "white screen of death" and gives immediate feedback.
class InitializationErrorApp extends StatelessWidget {
  final Object error;

  const InitializationErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'Application Failed to Start',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'A critical error occurred during initialization, and the app cannot continue. Please report this issue.\n\nError:\n$error',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// The original MyApp widget remains unchanged. It will only run if
// initialization is successful.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<FbUser?>(
        stream: FbAuth.instance.authStateChanges,
        builder: (context, snapshot) {
          // Case 1: An error occurred in the stream (e.g., Firebase config issue)
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: Something went wrong with Firebase authentication. \n\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          // Case 2: Waiting for the first authentication state event
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while we check the auth state.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Case 3: We have data. Check if the user is logged in or not.
          final user = snapshot.data;
          if (user == null) {
            // User is not logged in, show the authentication page.
            return const AuthPage();
          } else {
            // User is logged in, show the main app page.
            return const MainTabPage();
          }
        },
      ),
    );
  }
}
