// ============================================================
// Signup Screen - Role Selection + Role-Based Registration Forms
// ============================================================
// Allows users to select their role and fill the appropriate
// registration form. Supported roles: Driver, Rider, Customer, Admin.
// Also supports Google Sign-In for all roles.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/google_auth_service.dart';
import '../../../features/home/screens/home_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

// Import role-specific form widgets
import '../widgets/driver_signup_form.dart';
import '../widgets/rider_signup_form.dart';
import '../widgets/customer_signup_form.dart';
import '../widgets/admin_signup_form.dart';

enum _RoleOption { driver, rider, customer, hotel, admin }

class SignupScreen extends StatefulWidget {
  final String? initialRole; // e.g. "customer" to pre-select customer signup
  const SignupScreen({super.key, this.initialRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  _RoleOption? _selectedRole;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-select role if initialRole is provided (e.g. from customer login)
    if (widget.initialRole == 'customer') {
      _selectedRole = _RoleOption.customer;
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      // Determine role from selection (default CUSTOMER)
      String role = 'CUSTOMER';
      if (_selectedRole == _RoleOption.driver) {
        role = 'DRIVER';
      } else if (_selectedRole == _RoleOption.rider) {
        role = 'RIDER';
      } else if (_selectedRole == _RoleOption.hotel) {
        role = 'HOTEL';
      }

      final account = await GoogleAuthService.instance.signIn();
      if (account == null) {
        // User cancelled Google sign-in
        return;
      }
      final idToken = await GoogleAuthService.instance.getIdToken();
      if (idToken == null) {
        throw Exception('Could not obtain Google ID token');
      }

      final auth = context.read<AuthProvider>();
      final success = await auth.googleSignIn(idToken, role: role);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Google sign-in failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your role to register',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Google Sign-In Button
                OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _googleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _googleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata,
                          color: Colors.red, size: 30),
                  label: Text(
                    _googleLoading ? 'Signing in...' : 'Continue with Google',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Role Selection Cards
                _RoleCard(
                  icon: Icons.directions_car,
                  title: 'Driver',
                  subtitle: 'I want to drive',
                  selected: _selectedRole == _RoleOption.driver,
                  onTap: () => setState(() => _selectedRole = _RoleOption.driver),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.person_pin,
                  title: 'Rider',
                  subtitle: 'I need a ride home',
                  selected: _selectedRole == _RoleOption.rider,
                  onTap: () => setState(() => _selectedRole = _RoleOption.rider),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.local_taxi,
                  title: 'Customer',
                  subtitle: 'I own a vehicle',
                  selected: _selectedRole == _RoleOption.customer,
                  onTap: () => setState(() => _selectedRole = _RoleOption.customer),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.hotel,
                  title: 'Hotel',
                  subtitle: 'Partner hotel',
                  selected: _selectedRole == _RoleOption.hotel,
                  onTap: () => setState(() => _selectedRole = _RoleOption.hotel),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin',
                  subtitle: 'System administrator',
                  selected: _selectedRole == _RoleOption.admin,
                  onTap: () => setState(() => _selectedRole = _RoleOption.admin),
                ),
                const SizedBox(height: 24),

                // Dynamic Role Form
                if (_selectedRole != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildRoleForm(),
                ],

                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: TextStyle(color: Colors.grey.shade600)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Login',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleForm() {
    switch (_selectedRole) {
      case _RoleOption.driver:
        return const DriverSignupForm();
      case _RoleOption.rider:
        return const RiderSignupForm();
      case _RoleOption.customer:
        return const CustomerSignupForm();
      case _RoleOption.hotel:
        return const HotelSignupForm();
      case _RoleOption.admin:
        return const AdminSignupForm();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ============================================================
// Hotel Signup Form
// ============================================================
class HotelSignupForm extends StatefulWidget {
  const HotelSignupForm({super.key});
  @override
  State<HotelSignupForm> createState() => _HotelSignupFormState();
}

class _HotelSignupFormState extends State<HotelSignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _hotelName = TextEditingController();
  final _license = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _hotelName.dispose();
    _license.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signup({
      'role': 'HOTEL',
      'hotelName': _hotelName.text.trim(),
      'hotelLicenseNumber': _license.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'contactPhone': _phone.text.trim(),
      'contactEmail': _email.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'phone': _phone.text.trim(),
    });
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hotel registered! Wait for admin approval.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
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
          _field(_hotelName, 'Hotel Name *', Icons.hotel),
          const SizedBox(height: 12),
          _field(_license, 'Hotel License Number *', Icons.badge_outlined),
          const SizedBox(height: 12),
          _field(_address, 'Address *', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _field(_city, 'City *', Icons.location_city),
          const SizedBox(height: 12),
          _field(_phone, 'Contact Phone *', Icons.phone, number: true),
          const SizedBox(height: 12),
          _field(_email, 'Contact Email *', Icons.email, email: true),
          const SizedBox(height: 12),
          _field(_password, 'Password *', Icons.lock, obscure: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Register as Hotel'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false, bool email = false, bool number = false}) {
    return TextFormField(
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
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

// ============================================================
// Role Selection Card
// ============================================================
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo.shade50 : Colors.grey.shade50,
          border: Border.all(
            color: selected ? Colors.indigo : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.indigo : Colors.grey, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.indigo : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.indigo),
          ],
        ),
      ),
    );
  }
}