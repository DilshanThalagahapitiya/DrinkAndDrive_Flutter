// ============================================================
// My Rides / Tickets Screen (Driver & Rider)
// ============================================================
// Shows received tickets (ASSIGNED), can Accept or Cancel.
// Displays all rides: ASSIGNED, UPCOMING, ONGOING, COMPLETED.
// Works for both driver and rider roles.
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'ride_edit_screen.dart';

class MyRidesScreen extends StatefulWidget {
  final String? statusFilter; // Optional: "UPCOMING", "COMPLETED", "ASSIGNED", etc.
  final String role; // "driver" or "rider" — determines which API endpoint to use
  const MyRidesScreen({super.key, this.statusFilter, this.role = 'driver'});
  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  List<dynamic> _rides = [];
  bool _loading = true;
  String _error = '';

  // API endpoints based on role
  String get _ticketsEndpoint =>
      widget.role == 'rider' ? '/api/rider/rides' : '/api/driver/rides';

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  List<dynamic> get _filteredRides {
    if (widget.statusFilter == null || widget.statusFilter!.isEmpty) return _rides;
    final statuses = widget.statusFilter!
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return _rides.where((r) => statuses.contains(r['status'] ?? '')).toList();
  }

  Future<void> _fetchRides() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await ApiClient.instance.get(_ticketsEndpoint);
      setState(() {
        _rides = (res['data']['rides'] as List? ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed: $e'; _loading = false; });
    }
  }

  Future<void> _action(String rideId, String action) async {
    try {
      await ApiClient.instance.patch('$_ticketsEndpoint/$rideId', {'action': action});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'ACCEPT' ? '✅ Ticket accepted!' : '❌ Ticket cancelled'),
          backgroundColor: action == 'ACCEPT' ? Colors.green : Colors.red,
        ),
      );
      _fetchRides();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    return dt == null ? d : dt.toLocal().toString().replaceRange(16, 19, '');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ASSIGNED': return Colors.amber;
      case 'UPCOMING': return Colors.indigo;
      case 'ONGOING': return Colors.green;
      case 'COMPLETED': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRider = widget.role == 'rider';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(isRider ? 'My Rides / Tickets (Rider)' : 'My Rides / Tickets'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(_error, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _fetchRides, child: const Text('Retry')),
                ]))
              : _filteredRides.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No rides in this section'),
                      const SizedBox(height: 4),
                      Text(
                        widget.statusFilter == null || widget.statusFilter!.isEmpty
                            ? 'When admin assigns you a ride, it will appear here.'
                            : 'No ${widget.statusFilter!.toLowerCase().replaceAll('_', ' ')} rides yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetchRides,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRides.length,
                        itemBuilder: (ctx, i) {
                          final ride = _filteredRides[i];
                          final status = ride['status'] ?? '';
                          return InkWell(
                            // ASSIGNED tickets are ONLY for Accept/Cancel — not viewable.
                            // Only non-ASSIGNED rides (UPCOMING/ONGOING/COMPLETED) open the edit screen.
                            onTap: status == 'ASSIGNED'
                                ? null
                                : () async {
                                    // Refresh rides when returning from the edit/workflow screen
                                    // so COMPLETED status is always up to date (no stale Complete button).
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RideEditScreen(ride: ride, role: widget.role),
                                      ),
                                    );
                                    _fetchRides();
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Card(
                              elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(ride['startTime'] ?? ''),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    const Icon(Icons.trip_origin, size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('${ride['pickupLocation'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.flag, size: 18, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('${ride['dropLocation'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  ]),
                                  const SizedBox(height: 10),
                                  Text('👤 Customer: ${ride['customerName'] ?? '-'} • ${ride['customerNumber'] ?? ''}', style: const TextStyle(fontSize: 13)),
                                  Text('🚘 ${ride['vehicleType'] ?? '-'} • ⚙️ ${ride['transmission'] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  // Show other side's status
                                  if (isRider) ...[
                                    Text('🚗 Driver: ${ride['driver']?['fullName'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    if (ride['driverCancelled'] == true)
                                      Text('❌ Driver cancelled this ticket', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600))
                                    else if (ride['driverAccepted'] == true)
                                      Text('✅ Driver accepted', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600))
                                    else if (status == 'ASSIGNED')
                                      Text('⏳ Driver has not accepted yet', style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600)),
                                  ] else ...[
                                    Text('🙋 Rider: ${ride['rider']?['fullName'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    if (ride['riderCancelled'] == true)
                                      Text('❌ Rider cancelled this ticket', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600))
                                    else if (ride['riderAccepted'] == true)
                                      Text('✅ Rider accepted', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600))
                                    else if (status == 'ASSIGNED')
                                      Text('⏳ Rider has not accepted yet', style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600)),
                                  ],
                                  if (ride['specialNote'] != null && ride['specialNote'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text('📝 ${ride['specialNote']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                    ),

                                  // Accept/Cancel buttons for ASSIGNED tickets.
                                  // If THIS user already accepted, show a waiting message instead.
                                  if (status == 'ASSIGNED') ...[
                                    const SizedBox(height: 12),
                                    if ((isRider && ride['riderAccepted'] == true) ||
                                        (!isRider && ride['driverAccepted'] == true))
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                isRider
                                                    ? '✅ You accepted — waiting for the driver to accept...'
                                                    : '✅ You accepted — waiting for the rider to accept...',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else ...[
                                      Row(children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _action(ride['id'], 'ACCEPT'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            child: const Text('✅ Accept Ticket'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _action(ride['id'], 'CANCEL'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                            child: const Text('❌ Cancel'),
                                          ),
                                        ),
                                      ]),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                        },
                      ),
                    ),
    );
  }
}