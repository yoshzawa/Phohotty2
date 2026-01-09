import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final local = LocalStorageService();
  late Future<List<Map<String, dynamic>>> _galleryFuture;

  @override
  void initState() {
    super.initState();
    // 不要な権限チェックを削除し、直接ギャラリーを読み込む
    _galleryFuture = local.loadGallery();
  }

  void _reloadGallery() {
    setState(() {
      _galleryFuture = local.loadGallery();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ギャラリー"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadGallery,
            tooltip: "更新",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.label),
                label: const Text("画像にタグ付け"),
                // ページ遷移後にギャラリーをリロードするために、.then() を使用
                onPressed: () => Navigator.pushNamed(context, "/tag-lens").then((_) => _reloadGallery()),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _galleryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // 主にファイルの読み込みエラーなどをキャッチする
                  return Center(
                      child: Text("エラーが発生しました: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red)));
                }
                final items = snapshot.data;
                if (items == null || items.isEmpty) {
                  return const Center(child: Text("まだ画像がありません"));
                }
                return _buildGalleryGrid(items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final filePath = item["path"];
        final tags = (item["tags"] as List).join(", ");

        // ファイルが存在しない場合のエラーハンドリングを追加
        final file = File(filePath);
        if (!file.existsSync()) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("画像なし", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return GridTile(
          footer: GridTileBar(
            backgroundColor: Colors.black45,
            title: Text(
              tags,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          child: Image.file(file, fit: BoxFit.cover),
        );
      },
    );
  }
}
