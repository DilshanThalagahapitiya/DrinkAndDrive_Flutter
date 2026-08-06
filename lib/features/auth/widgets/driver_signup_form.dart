// ============================================================
// Driver Signup Form
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../features/home/screens/home_screen.dart';

class DriverSignupForm extends StatefulWidget {
  const DriverSignupForm({super.key});
  @override
  State<DriverSignupForm> createState() => _DriverSignupFormState();
}

class _DriverSignupFormState extends State<DriverSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nic = TextEditingController();
  final _city = TextEditingController();
  final _licenseNo = TextEditingController();
  final _password = TextEditingController();
  String _licenseCategory = 'LIGHT_WEIGHT';
  String _vehicleType = 'CAR';
  String _transmission = 'AUTO';

  @override
  void dispose() {
    _fName.dispose(); _lName.dispose(); _email.dispose(); _phone.dispose();
    _nic.dispose(); _city.dispose(); _licenseNo.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final data = {
      'role': 'DRIVER',
      'email': _email.text.trim(),
      'password': _password.text,
      'firstName': _fName.text.trim(),
      'lastName': _lName.text.trim(),
      'phone': _phone.text.trim(),
      'nic': _nic.text.trim(),
      'city': _city.text.trim(),
      'licenseNumber': _licenseNo.text.trim(),
      'licenseCategory': _licenseCategory,
      'licenseLightExpiryDate': '2030-12-31',
      'licenseFrontImage': '/uploads/front.jpg',
      'licenseBackImage': '/uploads/back.jpg',
      'vehicleType': _vehicleType,
      'preferredGear': _transmission,
      'address': _city.text.trim(),
    };
    final success = await auth.signup(data);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted! Wait for admin approval.')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Personal Details'),
          _field(_fName, 'First Name *', Icons.person),
          _field(_lName, 'Last Name *', Icons.person_outline),
          _field(_email, 'Email *', Icons.email, email: true),
          _field(_phone, 'Phone Number *', Icons.phone, number: true),
          _field(_nic, 'NIC *', Icons.badge_outlined),
          _field(_city, 'City *', Icons.location_city),
          const SizedBox(height: 12),
          _sectionTitle('License Details'),
          _field(_licenseNo, 'License Number *', Icons.card_membership),
          DropdownButtonFormField<String>(
            value: _licenseCategory,
            decoration: const InputDecoration(
              labelText: 'License Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'LIGHT_WEIGHT', child: Text('Light Weight')),
              DropdownMenuItem(value: 'HEAVY', child: Text('Heavy')),
              DropdownMenuItem(value: 'BOTH', child: Text('Both')),
            ],
            onChanged: (v) => setState(() => _licenseCategory = v!),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Vehicle Preferences'),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: const InputDecoration(
              labelText: 'Preferred Vehicle',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'CAR', child: Text('Car')),
              DropdownMenuItem(value: 'VAN', child: Text('Van')),
              DropdownMenuItem(value: 'LORRY', child: Text('Lorry')),
              DropdownMenuItem(value: 'BUS', child: Text('Bus')),
              DropdownMenuItem(value: 'BIKE', child: Text('Motor Bike')),
              DropdownMenuItem(value: 'TUKTUK', child: Text('Three Wheeler')),
              DropdownMenuItem(value: 'SUV', child: Text('SUV')),
            ],
            onChanged: (v) => setState(() => _vehicleType = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _transmission,
            decoration: const InputDecoration(
              labelText: 'Transmission',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'AUTO', child: Text('Auto')),
              DropdownMenuItem(value: 'MANUAL', child: Text('Manual')),
              DropdownMenuItem(value: 'BOTH', child: Text('Both')),
            ],
            onChanged: (v) => setState(() => _transmission = v!),
          ),
          const SizedBox(height: 12),
          _field(_password, 'Password *', Icons.lock, obscure: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.indigo,
            ),
            child: const Text('Register as Driver'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false, bool email = false, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: email
            ? TextInputType.emailAddress
            : number
                ? TextInputType.phone
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}