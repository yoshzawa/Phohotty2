import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  CameraPosition? _initialCameraPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
    _loadPhotoMarkers();
  }

  Future<void> _setCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _initialCameraPosition = const CameraPosition(
          target: LatLng(35.6762, 139.6503),
          zoom: 12,
        );
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
    });
  }

  Future<void> _loadPhotoMarkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final photosSnapshot = await FirebaseFirestore.instance
        .collection('photos')
        .where('userId', isEqualTo: user.uid)
        .get();

    final Set<Marker> newMarkers = {};
    for (final doc in photosSnapshot.docs) {
      final data = doc.data();
      final location = data['location'] as GeoPoint?;
      final imageUrl = data['imageUrl'] as String?;
      final tags = (data['tags'] as List<dynamic>? ?? []).cast<String>();

      if (location != null && imageUrl != null) {
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(location.latitude, location.longitude),
          onTap: () => _showPhotoDialog(imageUrl, tags),
        );
        newMarkers.add(marker);
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('マーカーを再読み込みしました')),
      );
    }
  }

  void _showPhotoDialog(String imageUrl, List<String> tags) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(tags.join(', ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("画像MAPSNS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadPhotoMarkers,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition!,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: _markers,
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
