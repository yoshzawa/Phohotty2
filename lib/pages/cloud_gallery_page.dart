import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
      return Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gallery')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クラウドギャラリー'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserImageStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final stackTrace = snapshot.stackTrace;
            final user = _auth.currentUser;
            final uid = user?.uid ?? 'unknown_user';
            final firestorePath = 'users/$uid/gallery';

            String reason = 'Error fetching from Cloud Gallery';
            if (error is FirebaseException && error.code == 'permission-denied') {
              reason = 'Firestore permission denied in Cloud Gallery';
            }
            
            FirebaseCrashlytics.instance.setCustomKey('firestore_path', firestorePath);
            FirebaseCrashlytics.instance.setCustomKey('user_id', uid);
            FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason, fatal: false);

            debugPrint('Firestore Error reported to Crashlytics: $error');
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, color: Colors.red, size: 50),
                    SizedBox(height: 16),
                    Text(
                      'データの取得に失敗しました。',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'この問題は開発者に自動的に報告されました。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('アップロードされた写真はありません。'));
          }

          final imageDocs = snapshot.data!.docs;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: imageDocs.length,
            itemBuilder: (context, index) {
              final doc = imageDocs[index];
              final imageUrl = doc.get('imageUrl') as String?;

              if (imageUrl == null) {
                return const GridTile(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                );
              }

              return GridTile(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
