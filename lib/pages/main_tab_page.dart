import 'package:flutter/material.dart';
import 'home_page.dart';
import 'tag_lens_page.dart';
import 'gallery_page.dart';
class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  static _MainTabPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainTabPageState>();
  }

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 1;

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const TagLensPage(),
      GalleryPage(
        onGoToTagLens: () => switchTab(1),
      ),
      //const MapPage(),
      //const SnsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: switchTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'TagLens'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Gallery'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.smartphone), label: 'SNS'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
