// ============================================================
// Customer Rides Screen — Ride History + Fare Breakdown
// ============================================================
// Shows ALL rides requested by the customer.
// Completed rides display the total fare + full fare breakdown
// (base fare, distance, waiting) so the customer knows exactly
// how the amount was calculated.
// ============================================================

import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/network/api_client.dart';

class CustomerRidesScreen extends StatefulWidget {
  const CustomerRidesScreen({super.key});

  @override
  State<CustomerRidesScreen> createState() => _CustomerRidesScreenState();
}

class _CustomerRidesScreenState extends State<CustomerRidesScreen> {
  List<dynamic> _rides = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await ApiClient.instance.get('/api/customer/rides');
      setState(() {
        _rides = (res['data']['rides'] as List? ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed: $e'; _loading = false; });
    }
  }

  String _formatDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    final local = dt.toLocal();
    final date = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date  $time';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING_REQUEST': return Colors.orange;
      case 'ASSIGNED': return Colors.amber.shade700;
      case 'UPCOMING': return Colors.indigo;
      case 'ONGOING': return Colors.green;
      case 'COMPLETED': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING_REQUEST': return Icons.hourglass_top;
      case 'ASSIGNED': return Icons.event_available;
      case 'UPCOMING': return Icons.event;
      case 'ONGOING': return Icons.directions_car;
      case 'COMPLETED': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  // Parse the fare breakdown JSON stored on the ride
  Map<String, dynamic>? _parseBreakdown(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw.toString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('My Rides'),
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
              : _rides.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No ride requests yet'),
                      const SizedBox(height: 4),
                      const Text(
                        'Request a driver to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetchRides,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rides.length,
                        itemBuilder: (ctx, i) {
                          final ride = _rides[i] as Map<String, dynamic>;
                          final status = ride['status']?.toString() ?? '';
                          final statusColor = _statusColor(status);
                          final totalFare = ride['totalFare'];
                          final breakdown = _parseBreakdown(ride['fareBreakdown']);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status header row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(children: [
                                          Icon(_statusIcon(status), size: 14, color: statusColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            status.replaceAll('_', ' '),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      Text(
                                        _formatDate(ride['startTime']?.toString() ?? ride['createdAt']?.toString() ?? ''),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Pickup → Drop
                                  Row(children: [
                                    const Icon(Icons.trip_origin, size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('${ride['pickupLocation'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.flag, size: 18, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text('${ride['dropLocation'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                  ]),
                                  const SizedBox(height: 8),

                                  // Vehicle info
                                  Text('🚘 ${ride['vehicleType'] ?? '-'} • ⚙️ ${ride['transmission'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  if (ride['specialNote'] != null && ride['specialNote'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('📝 ${ride['specialNote']}',
                                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                    ),

                                  // Driver & Rider assigned
                                  if ((ride['driver'] as Map?) != null ||
                                      (ride['rider'] as Map?) != null) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      if ((ride['driver'] as Map?) != null) ...[
                                        Icon(Icons.person, size: 15, color: Colors.indigo.shade300),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text('${(ride['driver'] as Map?)?['fullName'] ?? '-'}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      if ((ride['rider'] as Map?) != null) ...[
                                        Icon(Icons.person_pin, size: 15, color: Colors.orange.shade300),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text('${(ride['rider'] as Map?)?['fullName'] ?? '-'}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: Colors.orange)),
                                        ),
                                      ],
                                    ]),
                                  ],

                                  // ========================================
                                  // 💵 FARE SUMMARY — for completed rides
                                  // ========================================
                                  if (status == 'COMPLETED' && totalFare != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF1F2937), Color(0xFF374151)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const Text('💵 Fare Summary',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber)),
                                          const SizedBox(height: 8),
                                          if (breakdown != null) ...[
                                            _fareRow('🚦 Base Fare', 'Rs. ${breakdown['baseFare'] ?? 0}'),
                                            _fareRow(
                                              '📏 Distance (${breakdown['distanceKm'] ?? 0} km)',
                                              'Rs. ${breakdown['distanceCost'] ?? 0}',
                                            ),
                                            if ((breakdown['waitingMin'] ?? 0) > 0)
                                              _fareRow(
                                                '⏱️ Waiting (${breakdown['waitingMin']} min)',
                                                'Rs. ${breakdown['waitingCost'] ?? 0}',
                                              ),
                                            const Divider(color: Colors.white24, height: 16),
                                          ],
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('💰 Total Amount',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                              Text('Rs. $totalFare',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.amber)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _fareRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );
}