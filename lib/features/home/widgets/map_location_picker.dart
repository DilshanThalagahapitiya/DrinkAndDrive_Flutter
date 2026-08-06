// ============================================================
// MapLocationPicker — Location entry (works WITHOUT billing/map)
// - Driver can just TYPE the pickup/drop location
// - Optional Google map for pinning (only renders with billing)
// - On "Use This": always returns the typed address
// - If a pin is set, also returns coords for routing
// ============================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLocationPicker extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final ValueChanged<String> onAddressChanged;
  final ValueChanged<({double lat, double lng})>? onCoordsChanged;
  final bool enabled;
  const MapLocationPicker({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
    required this.onAddressChanged,
    this.onCoordsChanged,
    this.enabled = true,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  LatLng? _selected;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialAddress ?? '';
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) _selected = LatLng(lat, lng);
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Try to auto-get current location (works if permission granted)
  Future<void> _fetchCurrentLocation() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied ||
          hasPermission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {}
  }

  void _goToCurrentLocation() {
    if (_currentLocation == null) {
      _fetchCurrentLocation();
      return;
    }
    setState(() {
      _selected = _currentLocation;
      _searchCtrl.text =
          '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}';
    });
  }

  // WORKS WITHOUT MAP: returns the typed address (coords only if pinned)
  void _confirm() {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a location.')),
      );
      return;
    }
    widget.onAddressChanged(text);

    if (_selected != null && widget.onCoordsChanged != null) {
      widget.onCoordsChanged!((lat: _selected!.latitude, lng: _selected!.longitude));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: TextField(
          controller: _searchCtrl,
          enabled: widget.enabled,
          decoration: const InputDecoration(
            hintText: '🔍 Type location e.g. Colombo 07',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.enabled ? _confirm : null,
            child: const Text('✅ Use This',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map is OPTIONAL — it shows only when tiles load (billing enabled).
          // Without billing it stays blank, but typing + Use This still works.
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selected ?? const LatLng(7.8731, 80.7718),
              zoom: 14,
            ),
            onMapCreated: (controller) {},
            onTap: (latLng) {
              setState(() {
                _selected = latLng;
                _searchCtrl.text =
                    '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
              });
            },
            markers: {
              if (_selected != null)
                Marker(markerId: const MarkerId('pin'), position: _selected!),
            },
          ),
          // My Location button overlay (top-right of map)
          Positioned(
            right: 14,
            top: 14,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              elevation: 4,
              child: InkWell(
                onTap: _goToCurrentLocation,
                borderRadius: BorderRadius.circular(30),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.my_location, color: Colors.indigo, size: 24),
                ),
              ),
            ),
          ),
          // Hint: typing is enough; pin is optional
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Text(
                '✍️ Type the location above, then tap ✅ Use This. (Tapping the map adds exact coordinates if available.)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}