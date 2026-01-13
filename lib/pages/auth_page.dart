import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_tab_page.dart';
import 'sign_in_page.dart';

/// A widget that handles the authentication state and displays the appropriate screen.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while waiting for the auth state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If the user is logged in, show the main content of the app.
        if (snapshot.hasData) {
          return const MainTabPage();
        }

        // If the user is not logged in, show the sign-in page.
        return const SignInPage();
      },
    );
  }
}
