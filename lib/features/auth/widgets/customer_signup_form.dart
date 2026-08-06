// ============================================================
// Customer Signup Form
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../features/home/screens/home_screen.dart';

class CustomerSignupForm extends StatefulWidget {
  const CustomerSignupForm({super.key});
  @override
  State<CustomerSignupForm> createState() => _CustomerSignupFormState();
}

class _CustomerSignupFormState extends State<CustomerSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nic = TextEditingController();
  final _location = TextEditingController();
  final _vehicleType = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _password = TextEditingController();
  String _transmission = 'AUTO';

  @override
  void dispose() {
    _fName.dispose(); _lName.dispose(); _email.dispose(); _phone.dispose();
    _nic.dispose(); _location.dispose(); _vehicleType.dispose();
    _vehicleNumber.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final data = {
      'role': 'CUSTOMER',
      'email': _email.text.trim(),
      'password': _password.text,
      'firstName': _fName.text.trim(),
      'lastName': _lName.text.trim(),
      'phone': _phone.text.trim(),
      'nic': _nic.text.trim(),
      'customerLocation': _location.text.trim(),
      'customerVehicleType': _vehicleType.text.trim(),
      'customerTransmission': _transmission,
      'customerVehicleNumber': _vehicleNumber.text.trim(),
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
          _section('Personal Details', [
            _field(_fName, 'First Name *', Icons.person),
            _field(_lName, 'Last Name *', Icons.person_outline),
            _field(_email, 'Email', Icons.email, email: true, optional: true),
            _field(_phone, 'Phone Number *', Icons.phone, number: true),
            _field(_nic, 'NIC', Icons.badge_outlined, optional: true),
            _field(_location, 'Location (Google Maps) *', Icons.map),
          ]),
          _section('About Vehicle', [
            _field(_vehicleType, 'What is your vehicle? *', Icons.directions_car),
            DropdownButtonFormField<String>(
              value: _transmission,
              decoration: const InputDecoration(
                labelText: 'Transmission Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'AUTO', child: Text('Auto')),
                DropdownMenuItem(value: 'MANUAL', child: Text('Manual')),
              ],
              onChanged: (v) => setState(() => _transmission = v!),
            ),
            const SizedBox(height: 12),
            _field(_vehicleNumber, 'Vehicle Number *', Icons.confirmation_number),
          ]),
          _section('Login Details', [
            _field(_password, 'Password *', Icons.lock, obscure: true),
          ]),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.indigo,
            ),
            child: const Text('Register as Customer'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> fields) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          ...fields,
        ],
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false, bool email = false, bool number = false, bool optional = false}) {
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
        validator: (v) => (v == null || v.isEmpty) && !optional ? 'Required' : null,
      ),
    );
  }
}