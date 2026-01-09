import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fb_auth.dart';
import 'user_create_page.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サインイン')), // Changed title
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('アカウントにサインインしてください', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // Set button height
                  ),
                  onPressed: () async {
                    try {
                      final result = await FbAuth.instance.signInWithGoogle();
                      if (result == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('サインインがキャンセルされました')));
                      }
                    } on FirebaseAuthException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('サインインに失敗しました: ${e.message}')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('予期せぬエラーが発生しました: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.login, color: Colors.red), // Example color
                  label: const Text('Googleでサインイン'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () async {
                    try {
                      final result = await FbAuth.instance.signInWithMicrosoft();
                       if (result == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('サインインがキャンセルされました')));
                      }
                    } on FirebaseAuthException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('サインインに失敗しました: ${e.message}')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('予期せぬエラーが発生しました: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.login, color: Colors.blue), // Example color
                  label: const Text('Microsoftでサインイン'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserCreatePage()),
                    );
                  },
                  child: const Text('または、メールアドレスでアカウント作成'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
