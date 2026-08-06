// ============================================================
// Rider Signup Form
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../features/home/screens/home_screen.dart';

class RiderSignupForm extends StatefulWidget {
  const RiderSignupForm({super.key});
  @override
  State<RiderSignupForm> createState() => _RiderSignupFormState();
}

class _RiderSignupFormState extends State<RiderSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nic = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _licenseNo = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _fName.dispose(); _lName.dispose(); _email.dispose(); _phone.dispose();
    _nic.dispose(); _city.dispose(); _address.dispose(); _licenseNo.dispose();
    _emergencyName.dispose(); _emergencyPhone.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final data = {
      'role': 'RIDER',
      'email': _email.text.trim(),
      'password': _password.text,
      'firstName': _fName.text.trim(),
      'lastName': _lName.text.trim(),
      'phone': _phone.text.trim(),
      'nic': _nic.text.trim(),
      'city': _city.text.trim(),
      'address': _address.text.trim(),
      'riderLicenseNumber': _licenseNo.text.trim(),
      'emergencyContactName': _emergencyName.text.trim(),
      'emergencyContactPhone': _emergencyPhone.text.trim(),
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
            _field(_email, 'Email *', Icons.email, email: true),
            _field(_phone, 'Phone Number *', Icons.phone, number: true),
            _field(_nic, 'NIC', Icons.badge_outlined),
            _field(_address, 'Home Address *', Icons.home),
            _field(_city, 'City *', Icons.location_city),
            _field(_licenseNo, 'License Number *', Icons.card_membership),
          ]),
          _section('Emergency Contact', [
            _field(_emergencyName, 'Emergency Contact Name *', Icons.contact_emergency),
            _field(_emergencyPhone, 'Emergency Contact Phone *', Icons.phone_in_talk, number: true),
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
            child: const Text('Register as Rider'),
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