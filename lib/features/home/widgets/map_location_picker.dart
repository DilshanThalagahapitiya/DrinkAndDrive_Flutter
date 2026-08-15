// ============================================================
// MapLocationPicker — Location entry (no Google Maps dependency)
// - Driver can TYPE the pickup/drop location
// - "Use Current Location" button fills coords via geolocator
// - On "Use This": always returns the typed address
// - If a location is set, also returns coords for routing
// ============================================================

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  ({double lat, double lng})? _selected;
  ({double lat, double lng})? _currentLocation;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialAddress ?? '';
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) _selected = (lat: lat, lng: lng);
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
          _currentLocation = (lat: position.latitude, lng: position.longitude);
        });
      }
    } catch (_) {}
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentLocation == null) {
      await _fetchCurrentLocation();
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch current location. Enable location permissions.')),
        );
        return;
      }
    }
    setState(() {
      _selected = _currentLocation;
      _searchCtrl.text =
          '${_currentLocation!.lat.toStringAsFixed(6)}, ${_currentLocation!.lng.toStringAsFixed(6)}';
    });
  }

  // Returns the typed address (coords only if current location was used)
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
      widget.onCoordsChanged!((lat: _selected!.lat, lng: _selected!.lng));
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Use current location (geolocator, no Google Maps)
            OutlinedButton.icon(
              onPressed: widget.enabled ? _goToCurrentLocation : null,
              icon: const Icon(Icons.my_location, color: Colors.indigo),
              label: const Text('📍 Use My Current Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            // Hint card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: const Text(
                '✍️ Type the location above, then tap ✅ Use This.\n'
                'Optionally tap "Use My Current Location" to attach GPS coordinates.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}