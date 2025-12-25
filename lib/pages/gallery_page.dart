import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
    _galleryFuture = _loadGalleryWithPermissionCheck();
  }

  Future<List<Map<String, dynamic>>> _loadGalleryWithPermissionCheck() async {
    // 1. Permission Check
    var status = await Permission.photos.status;
    if (status.isDenied) {
      // 2. Request Permission
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      // 3. Load Gallery if permission is granted
      return local.loadGallery();
    } else {
      // 4. Handle permission denial
      // You can show a dialog or a message to the user.
      throw Exception('Photo library permission was denied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ギャラリー")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.label),
                label: const Text("画像にタグ付け"),
                onPressed: () => Navigator.pushNamed(context, "/tag-lens"),
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
                  return Center(
                      child: Text("エラー: ${snapshot.error}",
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
          child: Image.file(File(filePath), fit: BoxFit.cover),
        );
      },
    );
  }
}