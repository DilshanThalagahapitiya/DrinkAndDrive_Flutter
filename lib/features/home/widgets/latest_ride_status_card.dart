// ============================================================
// Latest Ride Request Status Card (Customer)
// ============================================================
// Shows the latest ride request's status on the customer home:
//   - Request submitted? (PENDING_REQUEST)
//   - Driver & Rider assigned? (ASSIGNED)
//   - Did the driver acknowledge? (driverAccepted)
//   - Did the rider acknowledge? (riderAccepted)
//   - Request cancelled? (driverCancelled / riderCancelled)
//   - Ride ongoing / completed (ONGOING / COMPLETED)
// Supports an external refreshTrigger to refetch when the parent
// knows the data changed (e.g. after submitting a new request).
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class LatestRideStatusCard extends StatefulWidget {
  final int refreshTrigger;
  const LatestRideStatusCard({super.key, this.refreshTrigger = 0});

  @override
  State<LatestRideStatusCard> createState() => _LatestRideStatusCardState();
}

class _LatestRideStatusCardState extends State<LatestRideStatusCard> {
  Map<String, dynamic>? _ride;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchLatest();
  }

  @override
  void didUpdateWidget(covariant LatestRideStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchLatest();
    }
  }

  Future<void> _fetchLatest() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await ApiClient.instance.get('/api/customer/rides?limit=1');
      final rides = res['data']['rides'] as List? ?? [];
      setState(() {
        _ride = rides.isEmpty ? null : (rides.first as Map<String, dynamic>);
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

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING_REQUEST': return 'Waiting for admin to assign driver & rider';
      case 'ASSIGNED': return 'Driver & rider assigned — waiting for them to accept';
      case 'UPCOMING': return 'Scheduled — both driver & rider accepted';
      case 'ONGOING': return 'Ride in progress';
      case 'COMPLETED': return 'Ride completed';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Latest Request Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                  onPressed: _fetchLatest,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(_error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _fetchLatest, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_ride == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No ride requests yet.\nRequest a driver to get started.'),
                      Text(
                        'Your latest request status will appear here.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildStatusContent(_ride!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(Map<String, dynamic> ride) {
    final status = ride['status'] ?? 'PENDING_REQUEST';
    final driver = ride['driver'] as Map<String, dynamic>?;
    final rider = ride['rider'] as Map<String, dynamic>?;
    final driverAccepted = ride['driverAccepted'] == true;
    final riderAccepted = ride['riderAccepted'] == true;
    final driverCancelled = ride['driverCancelled'] == true;
    final riderCancelled = ride['riderCancelled'] == true;
    final isCancelled = driverCancelled || riderCancelled;
    final statusColor = _statusColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(_statusIcon(status), color: statusColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _statusLabel(status),
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _InfoRow(icon: Icons.trip_origin, color: Colors.green, text: '${ride['pickupLocation'] ?? '-'}'),
        _InfoRow(icon: Icons.flag, color: Colors.red, text: '${ride['dropLocation'] ?? '-'}'),
        _InfoRow(icon: Icons.schedule, color: Colors.indigo, text: _formatDate('${ride['startTime'] ?? ''}')),
        if (ride['vehicleType'] != null && ride['vehicleType'].toString().isNotEmpty)
          _InfoRow(icon: Icons.directions_car, color: Colors.orange, text: '${ride['vehicleType']} • ⚙️ ${ride['transmission'] ?? '-'}'),
        if (ride['specialNote'] != null && ride['specialNote'].toString().isNotEmpty)
          _InfoRow(icon: Icons.notes, color: Colors.blueGrey, text: '${ride['specialNote']}'),

        const SizedBox(height: 12),
        const Divider(height: 1),

        const SizedBox(height: 8),
        _AssignedUserTile(
          icon: Icons.person,
          label: 'Driver',
          name: driver?['fullName'] ?? 'Not assigned yet',
          accepted: driverAccepted,
          cancelled: driverCancelled,
          isAssigned: driver != null,
        ),

        const SizedBox(height: 6),
        _AssignedUserTile(
          icon: Icons.person_pin,
          label: 'Rider',
          name: rider?['fullName'] ?? 'Not assigned yet',
          accepted: riderAccepted,
          cancelled: riderCancelled,
          isAssigned: rider != null,
        ),

        if (isCancelled) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driverCancelled && riderCancelled
                        ? 'Driver and rider cancelled this request. Admin will re-assign.'
                        : driverCancelled
                            ? 'Driver cancelled this request. Admin will re-assign.'
                            : 'Rider cancelled this request. Admin will re-assign.',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 💵 Total Fare — shown to customer when the ride is completed
        if (status == 'COMPLETED' && (ride['totalFare'] ?? 0) > 0) ...[
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💵 Total Fare',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to pay',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Text('Rs. ${ride['totalFare']}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// Small info row (icon + text)
// ============================================================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Assigned user tile — shows driver/rider + acknowledge status
// ============================================================
class _AssignedUserTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;
  final bool accepted;
  final bool cancelled;
  final bool isAssigned;

  const _AssignedUserTile({
    required this.icon,
    required this.label,
    required this.name,
    required this.accepted,
    required this.cancelled,
    required this.isAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.indigo.shade300),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (cancelled)
          const Chip(
            label: Text('Cancelled', style: TextStyle(color: Colors.red, fontSize: 10)),
            backgroundColor: Color(0xFFFFEBEE),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        else if (accepted)
          const Chip(
            label: Text('✓ Accepted', style: TextStyle(color: Colors.green, fontSize: 10)),
            backgroundColor: Color(0xFFE8F5E9),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        else if (!isAssigned)
          const SizedBox()
        else
          Chip(
            label: const Text('⏳ Awaiting', style: TextStyle(color: Colors.amber, fontSize: 10)),
            backgroundColor: Colors.amber.shade50,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
