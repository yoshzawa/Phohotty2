import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fb_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _aiTaggingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _aiTaggingEnabled = prefs.getBool('aiTaggingEnabled') ?? true;
    });
  }

  Future<void> _saveAiTaggingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiTaggingEnabled', value);
    if (!mounted) return;
    setState(() {
      _aiTaggingEnabled = value;
    });
  }

  Future<void> _signOut() async {
    try {
      await FbAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('サインアウトしました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('サインアウトに失敗しました: $e')));
    }
  }

  Future<void> _requestPhotoPermission() async {
    final status = await Permission.photos.request();
    if (!mounted) return;

    if (status.isGranted) {
      _show('写真フォルダへのアクセスを許可しました');
    } else if (status.isPermanentlyDenied) {
      _openSettings();
    } else {
      _show('写真フォルダへのアクセスが拒否されました');
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;

    if (status.isGranted) {
      _show('位置情報へのアクセスを許可しました');
    } else if (status.isPermanentlyDenied) {
      _openSettings();
    } else {
      _show('位置情報へのアクセスが拒否されました');
    }
  }

  void _openSettings() {
    openAppSettings();
    _show('設定画面から権限を有効にしてください');
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
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
              if (ok == true) await _signOut();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Vision AI はデフォルトで有効。設定項目は削除しました。
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('写真フォルダへのアクセス許可'),
            onTap: _requestPhotoPermission,
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('位置情報へのアクセス許可'),
            onTap: _requestLocationPermission,
          ),
        ],
      ),
    );
  }
}