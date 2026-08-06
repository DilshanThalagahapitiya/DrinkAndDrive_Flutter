// ============================================================
// Signup Screen - Role Selection + Role-Based Registration Forms
// ============================================================
// Allows users to select their role and fill the appropriate
// registration form. Supported roles: Driver, Rider, Customer, Admin
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../../../features/home/screens/home_screen.dart';
import 'login_screen.dart';

// Import role-specific form widgets
import '../widgets/driver_signup_form.dart';
import '../widgets/rider_signup_form.dart';
import '../widgets/customer_signup_form.dart';
import '../widgets/admin_signup_form.dart';

enum _RoleOption { driver, rider, customer, admin }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  _RoleOption? _selectedRole;

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
      case _RoleOption.admin:
        return const AdminSignupForm();
      default:
        return const SizedBox.shrink();
    }
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