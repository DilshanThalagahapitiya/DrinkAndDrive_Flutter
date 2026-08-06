// ============================================================
// Ride Edit/View Screen (Driver & Rider)
// ============================================================
// DRIVER: editable pickup/drop (search on Google map), workflow
//         buttons (Waiting/Start/Continue/Complete), waiting
//         timer + saved intervals.
// RIDER:  read-only view — no editing, no buttons. Only sees
//         details + waiting intervals + total waiting.
// ============================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../widgets/map_location_picker.dart';

class RideEditScreen extends StatefulWidget {
  final dynamic ride;
  final String role;
  const RideEditScreen({super.key, required this.ride, this.role = 'driver'});
  @override
  State<RideEditScreen> createState() => _RideEditScreenState();
}

class _RideEditScreenState extends State<RideEditScreen> {
  late TextEditingController _pickupCtrl;
  late TextEditingController _dropCtrl;
  late String _status;
  bool _waiting = false;
  int _waitingSeconds = 0;
  Timer? _timer;
  bool _saving = false;
  List<Map<String, dynamic>> _intervals = [];

  // Coordinates, captured via Google Map picker
  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  // Odometer readings + proof images
  final TextEditingController _odoStartCtrl = TextEditingController();
  final TextEditingController _odoEndCtrl = TextEditingController();
  String? _odoStartImage;
  String? _odoEndImage;
  final ImagePicker _picker = ImagePicker();

  String get _endpoint =>
      widget.role == 'rider' ? '/api/rider/rides' : '/api/driver/rides';

  @override
  void initState() {
    super.initState();
    _pickupCtrl = TextEditingController(text: widget.ride['pickupLocation'] ?? '');
    _dropCtrl = TextEditingController(text: widget.ride['dropLocation'] ?? '');
    _pickupLat = widget.ride['pickupLatitude'] != null ? (widget.ride['pickupLatitude'] as num).toDouble() : null;
    _pickupLng = widget.ride['pickupLongitude'] != null ? (widget.ride['pickupLongitude'] as num).toDouble() : null;
    _dropLat = widget.ride['dropLatitude'] != null ? (widget.ride['dropLatitude'] as num).toDouble() : null;
    _dropLng = widget.ride['dropLongitude'] != null ? (widget.ride['dropLongitude'] as num).toDouble() : null;
    _odoStartCtrl.text = '${widget.ride['odoStart'] ?? ''}';
    _odoEndCtrl.text = '${widget.ride['odoEnd'] ?? ''}';
    _odoStartImage = widget.ride['odoStartImage'];
    _odoEndImage = widget.ride['odoEndImage'];
    _status = widget.ride['status'] ?? '';

    try {
      final raw = widget.ride['waitingIntervals'];
      if (raw is String && raw.isNotEmpty) {
        _intervals = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    _waiting = widget.ride['waitingSince'] != null;
    if (_waiting) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _odoStartCtrl.dispose();
    _odoEndCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _waitingSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _waitingSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _workflowAction(String action) async {
    setState(() => _saving = true);
    try {
      final res = await ApiClient.instance.patch('$_endpoint/${widget.ride['id']}', {
        'action': action,
        'pickupLocation': _pickupCtrl.text,
        'dropLocation': _dropCtrl.text,
        'pickupLatitude': _pickupLat,
        'pickupLongitude': _pickupLng,
        'dropLatitude': _dropLat,
        'dropLongitude': _dropLng,
        'odoStart': int.tryParse(_odoStartCtrl.text),
        'odoEnd': int.tryParse(_odoEndCtrl.text),
        'odoStartImage': _odoStartImage,
        'odoEndImage': _odoEndImage,
      });
      final updated = res['data']['ride'];
      setState(() {
        _status = updated['status'] ?? _status;
        _saving = false;
        if (action == 'WAITING') {
          _waiting = true;
          _startTimer();
        }
        if (action == 'CONTINUE') {
          _waiting = false;
          _stopTimer();
          try {
            final raw = updated['waitingIntervals'];
            if (raw is String && raw.isNotEmpty) {
              _intervals = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
            }
          } catch (_) {}
        }
        if (action == 'COMPLETE' || action == 'START') {
          _waiting = false;
          _stopTimer();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Done'), backgroundColor: Colors.indigo),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Capture odometer proof photo via camera
  Future<void> _captureOdoPhoto({required bool isStart}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() {
          if (isStart) {
            _odoStartImage = photo.path;
          } else {
            _odoEndImage = photo.path;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _pickOnMap({required bool isPickup}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialAddress: isPickup ? _pickupCtrl.text : _dropCtrl.text,
          initialLat: isPickup ? _pickupLat : _dropLat,
          initialLng: isPickup ? _pickupLng : _dropLng,
          onAddressChanged: (addr) {
            if (isPickup) _pickupCtrl.text = addr; else _dropCtrl.text = addr;
          },
          onCoordsChanged: (loc) {
            setState(() {
              if (isPickup) {
                _pickupLat = loc.lat;
                _pickupLng = loc.lng;
              } else {
                _dropLat = loc.lat;
                _dropLng = loc.lng;
              }
            });
          },
        ),
      ),
    );
  }

  String _fmt(int s) => '${(s ~/ 3600).toString().padLeft(2, '0')}:'
      '${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';

  Widget _fareRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isRider = widget.role == 'rider';
    final locked = _status == 'COMPLETED' || isRider;
    final odoS = int.tryParse(_odoStartCtrl.text);
    final odoE = int.tryParse(_odoEndCtrl.text);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(isRider ? 'Ride Details (View Only)' : 'Ride ${_status}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Column(children: [
                Text('🚗 ${ride['driver']?['fullName'] ?? 'Driver'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('🙋 ${ride['rider']?['fullName'] ?? 'Rider'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('🚘 ${ride['vehicleType'] ?? '-'} • ⚙️ ${ride['transmission'] ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 12),

            // Pickup (read-only for rider, editable for driver)
            TextFormField(
              controller: _pickupCtrl,
              readOnly: true,
              enabled: !locked,
              decoration: const InputDecoration(
                labelText: '📍 Pickup Location',
                prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // DRIVER ONLY: search pickup on map — COMMENTED OUT (no GCP billing).
            // KEPT for future development once billing is enabled.
            // if (!isRider) ...[
            //   OutlinedButton.icon(
            //     onPressed: locked ? null : () => _pickOnMap(isPickup: true),
            //     icon: const Icon(Icons.map, color: Colors.indigo),
            //     label: const Text('🗺️ Search Pickup on Map'),
            //     ...
            //   ),
            // ],
            if (!isRider && _pickupLat != null && _pickupLng != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('📍 ${_pickupLat!.toStringAsFixed(6)}, ${_pickupLng!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),

            // Drop (read-only for rider, editable for driver)
            TextFormField(
              controller: _dropCtrl,
              readOnly: true,
              enabled: !locked,
              decoration: const InputDecoration(
                labelText: '📍 Drop Location',
                prefixIcon: Icon(Icons.flag, color: Colors.red),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // DRIVER ONLY: search drop on map — COMMENTED OUT (no GCP billing).
            // KEPT for future development once billing is enabled.
            // if (!isRider) ...[
            //   OutlinedButton.icon(
            //     onPressed: locked ? null : () => _pickOnMap(isPickup: false),
            //     ...
            //   ),
            // ],
            if (!isRider && _dropLat != null && _dropLng != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('📍 ${_dropLat!.toStringAsFixed(6)}, ${_dropLng!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),

            // Other details (read-only)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(children: [
                _detail('👤 Customer', '${ride['customerName'] ?? '-'} • ${ride['customerNumber'] ?? ''}'),
                _detail('📝 Notes', '${ride['specialNote'] ?? '-'}'),
                _detail('🕐 Scheduled', '${ride['startTime'] ?? '-'}'),
                _detail('📅 Created', '${ride['createdAt'] ?? '-'}'),
              ]),
            ),
            const SizedBox(height: 16),

            // Waiting history — shown to BOTH
            if (_intervals.isNotEmpty || ((ride['waitingTotal'] ?? 0) as num) > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(children: [
                  const Text('⏱️ Waiting History',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 6),
                  for (var i = 0; i < _intervals.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Waiting ${i + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            '${_fmt(int.tryParse('${_intervals[i]['seconds'] ?? 0}') ?? 0)}'
                            '  (${_intervals[i]['start']?.toString()?.substring(11, 16) ?? ''} → '
                            '${_intervals[i]['end']?.toString()?.substring(11, 16) ?? ''})',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  if (((ride['waitingTotal'] ?? 0) as num) > 0) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Waiting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(_fmt(int.tryParse('${ride['waitingTotal'] ?? 0}') ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // Live waiting timer (driver only)
            if (_waiting && !isRider) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(children: [
                  Text('⏳ Waiting Timer ${_intervals.length + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    _fmt(_waitingSeconds),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // ---- DRIVER ONLY: ODOMETER SECTION (required for start/complete) ----
            if (!isRider) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🛣️ Odometer Readings',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),

                    // START odometer
                    TextField(
                      controller: _odoStartCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !locked,
                      decoration: const InputDecoration(
                        labelText: 'Start Odometer (required before Start)',
                        prefixIcon: Icon(Icons.speed, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: locked ? null : () => _captureOdoPhoto(isStart: true),
                      icon: const Icon(Icons.photo_camera, color: Colors.green),
                      label: Text(_odoStartImage != null
                          ? '📸 Start Odo Photo ✓ (optional)'
                          : '📸 Capture Start Odo Photo (optional)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // END odometer
                    TextField(
                      controller: _odoEndCtrl,
                      keyboardType: TextInputType.number,
                      enabled: !locked,
                      decoration: const InputDecoration(
                        labelText: 'End Odometer (required before Complete)',
                        prefixIcon: Icon(Icons.speed, color: Colors.red),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: locked ? null : () => _captureOdoPhoto(isStart: false),
                      icon: const Icon(Icons.photo_camera, color: Colors.red),
                      label: Text(_odoEndImage != null
                          ? '📷 End Odo Photo ✓ (optional)'
                          : '📷 Capture End Odo Photo (optional)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Distance preview
                    if (odoS != null && odoE != null && odoE >= odoS) ...[
                      Text('📏 Distance: ${odoE - odoS} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ] else if (odoS != null && odoE != null && odoE < odoS) ...[
                      Text('⚠️ End odometer must be >= Start',
                          style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],

                    const SizedBox(height: 8),

                    // Save button (uploads all odo + waiting + location to portal)
                    ElevatedButton.icon(
                      onPressed: _saving || locked
                          ? null
                          : () => _workflowAction('SAVE'),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('💾 Save for Portal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // DRIVER ONLY: workflow buttons
            if (!isRider) ...[
              // BEFORE START: Waiting active → hide Waiting button, show ONLY Start Ride
              if (_status == 'UPCOMING' || _status == 'ASSIGNED') ...[
                if (_waiting) ...[
                  // Waiting timer is running pre-start → show only Start Ride (full width)
                  ElevatedButton(
                    onPressed: _saving ? null : () => _workflowAction('START'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('▶ Start Ride'),
                  ),
                ] else ...[
                  // Normal pre-start → show Waiting + Start Ride
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _workflowAction('WAITING'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('⏳ Waiting'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _workflowAction('START'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('▶ Start Ride'),
                      ),
                    ),
                  ]),
                ],
              ],
              if (_status == 'ONGOING') ...[
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _workflowAction(_waiting ? 'CONTINUE' : 'WAITING'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _waiting ? Colors.orange : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_waiting ? '▶ Continue Ride' : '⏳ Waiting'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _workflowAction('COMPLETE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('✅ Complete Ride'),
                    ),
                  ),
                ]),
              ],
            ],

            // Completed footer (both driver & rider)
            if (_status == 'COMPLETED') ...[
              const SizedBox(height: 8),
              Center(
                child: Column(children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  const Text('Ride Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 12),

              // 💵 Total Fare Summary (driver & rider both see it)
              if (ride['totalFare'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F2937), Color(0xFF374151)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('💵 Fare Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                      const SizedBox(height: 12),
                      ...(() {
                        // Try to parse the fare breakdown JSON
                        Map<String, dynamic>? b;
                        try {
                          final raw = ride['fareBreakdown'];
                          if (raw is String && raw.isNotEmpty) {
                            final decoded = jsonDecode(raw);
                            if (decoded is Map<String, dynamic>) b = decoded;
                          }
                        } catch (_) {}
                        if (b != null) {
                          return [
                            _fareRow('🚦 Base Fare', 'Rs. ${b['baseFare'] ?? 0}'),
                            _fareRow('📏 Distance (${b['distanceKm'] ?? 0} km)', 'Rs. ${b['distanceCost'] ?? 0}'),
                            if ((b['waitingMin'] ?? 0) > 0)
                              _fareRow('⏱️ Waiting (${b['waitingMin']} min, ${b['chargedWaitingMin']} charged)', 'Rs. ${b['waitingCost'] ?? 0}'),
                            const Divider(color: Colors.white24, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('💰 Total Fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                Text('Rs. ${ride['totalFare']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.amber)),
                              ],
                            ),
                          ];
                        }
                        return [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('💰 Total Fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              Text('Rs. ${ride['totalFare']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.amber)),
                            ],
                          ),
                        ];
                      })(),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}