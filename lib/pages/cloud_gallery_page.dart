
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudGalleryPage extends StatefulWidget {
  const CloudGalleryPage({super.key});

  @override
  State<CloudGalleryPage> createState() => _CloudGalleryPageState();
}

class _CloudGalleryPageState extends State<CloudGalleryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _getUserImageStream() {
    final user = _auth.currentUser;
    if (user == null) {
      // ユーザーがログインしていない場合は空のストリームを返す
      return Stream.empty();
    }
    return _firestore
        .collection('photos') // Firestoreのコレクション名を'photos'と想定
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("クラウドギャラリー"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserImageStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("エラー: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("画像がありません"));
          }

          final documents = snapshot.data!.docs;
          return _buildGalleryGrid(documents);
        },
      ),
    );
  }

  Widget _buildGalleryGrid(List<QueryDocumentSnapshot> documents) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3列で表示
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['imageUrl'] as String?;
        final tags = (data['tags'] as List<dynamic>? ?? []).cast<String>();

        if (imageUrl == null || imageUrl.isEmpty) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          );
        }

        return GridTile(
          footer: GridTileBar(
            backgroundColor: Colors.black45,
            title: Text(
              tags.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.error, color: Colors.red)),
              );
            },
          ),
        );
      },
    );
  }
}
