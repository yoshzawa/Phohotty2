import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_tab_page.dart';
import 'pages/auth_page.dart';
import 'services/fb_auth.dart';

Future<void> main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request storage permission
  await PhotoManager.requestPermissionExtend();

  runApp(const MyApp());
}

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
