import 'package:flutter/material.dart';
import '../services/fb_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FbAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('サインアウトしました')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('サインアウトに失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
        actions: [
          IconButton(
            tooltip: 'サインアウト',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('サインアウト'),
                  content: const Text('サインアウトしますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
                  ],
                ),
              );
              if (ok == true) await _signOut(context);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("設定画面"),
      ),
    );
  }
}