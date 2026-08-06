// ============================================================
// Admin Signup Form
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../features/home/screens/home_screen.dart';

class AdminSignupForm extends StatefulWidget {
  const AdminSignupForm({super.key});
  @override
  State<AdminSignupForm> createState() => _AdminSignupFormState();
}

class _AdminSignupFormState extends State<AdminSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _fName.dispose(); _lName.dispose(); _email.dispose(); _phone.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final data = {
      'role': 'ADMIN',
      'email': _email.text.trim(),
      'password': _password.text,
      'firstName': _fName.text.trim(),
      'lastName': _lName.text.trim(),
      'fullName': '${_fName.text.trim()} ${_lName.text.trim()}',
      'phone': _phone.text.trim(),
    };
    final success = await auth.signup(data);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin registered!')),
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
          const Padding(
            padding: EdgeInsets.only(bottom: 8, top: 8),
            child: Text('Admin Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          _field(_fName, 'First Name *', Icons.person),
          _field(_lName, 'Last Name *', Icons.person_outline),
          _field(_email, 'Email *', Icons.email, email: true),
          _field(_phone, 'Phone Number *', Icons.phone, number: true),
          _field(_password, 'Password *', Icons.lock, obscure: true),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.indigo,
            ),
            child: const Text('Register as Admin'),
          ),
        ],
      ),
    );
  }

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