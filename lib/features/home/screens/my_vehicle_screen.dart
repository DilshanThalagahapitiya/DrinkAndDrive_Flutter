// ============================================================
// My Vehicle Screen (Customer)
// ============================================================
// Allows customers to add or edit their vehicle details
// at any time. Pre-populates with existing data.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});
  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _vehicleType = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _specialNote = TextEditingController();
  String _transmission = 'AUTO';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing customer profile data
    final user = context.read<AuthProvider>().user;
    final cp = user?.customerProfile;
    if (cp != null) {
      _location.text = cp['location'] as String? ?? '';
      _vehicleType.text = cp['vehicleType'] as String? ?? '';
      _vehicleNumber.text = cp['vehicleNumber'] as String? ?? '';
      _transmission = cp['transmission'] as String? ?? 'AUTO';
      _specialNote.text = cp['specialNote'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _location.dispose();
    _vehicleType.dispose();
    _vehicleNumber.dispose();
    _specialNote.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await ApiClient.instance.patch('/api/auth/me', {
        'customerLocation': _location.text.trim(),
        'customerVehicleType': _vehicleType.text.trim(),
        'customerTransmission': _transmission,
        'customerVehicleNumber': _vehicleNumber.text.trim(),
        'customerSpecialNote': _specialNote.text.trim().isEmpty
            ? null
            : _specialNote.text.trim(),
      });

      // Refresh user data so the profileComplete flag updates
      final auth = context.read<AuthProvider>();
      await auth.refreshUser();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vehicle details saved!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Vehicle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.directions_car,
                      color: Colors.orange, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Vehicle Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add or edit your vehicle details. You can update these at any time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // Location
                  _field(
                      _location, 'Location (Google Maps) *', Icons.map),
                  const SizedBox(height: 12),

                  // Vehicle Type
                  _field(
                      _vehicleType, 'Vehicle Type *', Icons.directions_car),
                  const SizedBox(height: 12),

                  // Transmission
                  DropdownButtonFormField<String>(
                    initialValue: _transmission,
                    decoration: const InputDecoration(
                      labelText: 'Transmission Type *',
                      prefixIcon: Icon(Icons.settings),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'AUTO', child: Text('Auto')),
                      DropdownMenuItem(value: 'MANUAL', child: Text('Manual')),
                    ],
                    onChanged: (v) => setState(() => _transmission = v!),
                  ),
                  const SizedBox(height: 12),

                  // Vehicle Number
                  _field(_vehicleNumber, 'Vehicle Number *',
                      Icons.confirmation_number),
                  const SizedBox(height: 12),

                  // Special Note
                  TextFormField(
                    controller: _specialNote,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Special Note (Optional)',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Vehicle Details',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}