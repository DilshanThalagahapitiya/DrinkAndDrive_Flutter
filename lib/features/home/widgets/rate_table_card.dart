// ============================================================
// Rate Table Card — shown on all dashboards
// ============================================================
// Fetches current rates from GET /api/rates (admin-updatable)
// and displays KM + waiting pricing.
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class RateTableCard extends StatefulWidget {
  const RateTableCard({super.key});
  @override
  State<RateTableCard> createState() => _RateTableCardState();
}

class _RateTableCardState extends State<RateTableCard> {
  Map<String, dynamic>? _rate;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/rates');
      setState(() {
        _rate = res['data']['rate'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed: $e'; _loading = false; });
    }
  }

  Widget _row(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.indigo.shade200, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: _loading
          ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          : _error.isNotEmpty
              ? Text(_error, style: const TextStyle(color: Colors.white, fontSize: 13))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.payments, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text('💰 Rate Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ]),
                  const SizedBox(height: 12),
                  _row('Base Fare', 'Rs. ${_rate?['baseFare'] ?? 0}', Icons.local_taxi),
                  _row('First ${_rate?['kmTierLimit'] ?? 10} km', 'Rs. ${_rate?['perKmRate'] ?? 0}/km', Icons.trip_origin),
                  _row('After ${_rate?['kmTierLimit'] ?? 10} km', 'Rs. ${_rate?['kmTier2Rate'] ?? 0}/km', Icons.flag),
                  _row('Max KM Rate', 'Rs. ${_rate?['kmMaxRate'] ?? 0}/km', Icons.speed),
                  const Divider(color: Colors.white24, height: 16),
                  _row('Waiting (1st ${_rate?['freeWaitingMin'] ?? 2} min)', 'FREE', Icons.hourglass_top),
                  _row('Waiting (after)', 'Rs. ${_rate?['waitingRatePerMin'] ?? 0}/min', Icons.timer),
                ]),
    );
  }
}