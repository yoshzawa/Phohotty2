import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class GalleryPage extends StatelessWidget {
  final VoidCallback onGoToTagLens;

  const GalleryPage({
    super.key,
    required this.onGoToTagLens,
  });

  @override
  Widget build(BuildContext context) {
    final local = LocalStorageService();

    return Scaffold(
      appBar: AppBar(title: const Text("ギャラリー")),
      body: Column(
        children: [
          // 🔼 上部ボタン
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.label),
                label: const Text("画像にタグ付け"),
                onPressed: onGoToTagLens,
              ),
            ),
          ),

          // 🔽 既存のギャラリー（中央）
          Expanded(
            child: FutureBuilder(
              future: local.loadGallery(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Center(child: Text("まだ画像がありません"));
                }

                return GridView.count(
                  crossAxisCount: 2,
                  children: items.map((item) {
                    return Column(
                      children: [
                        Expanded(
                          child: Image.file(
                            File(item["path"]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            (item["tags"] as List).join(", "),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
