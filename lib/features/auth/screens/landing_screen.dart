// ============================================================
// Landing Screen
// ============================================================
// Shows the DAD welcome/landing page when not logged in.
// - "Let's Hire" button → navigates to customer login
// - Shows admin-updatable support phone number
// - "or other logins" link → normal login screen
// ============================================================

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _contactPhone = '0763003678';

  @override
  void initState() {
    super.initState();
    _fetchContactPhone();
  }

  Future<void> _fetchContactPhone() async {
    try {
      final res = await ApiClient.instance.get('/api/rates', auth: false);
      final phone = res['data']?['rate']?['contactPhone'] as String?;
      if (phone != null && phone.isNotEmpty && mounted) {
        setState(() => _contactPhone = phone);
      }
    } catch (_) {
      // Fall back to default phone
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'D',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Hero Message
              const Text(
                "Don't Drive Drunk.\nGet Home Safely with DAD.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DAD connects you with verified safe drivers, riders, and partner hotels — so everyone gets home safely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // LET'S HIRE button
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to customer login mode
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(isCustomerMode: true),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_car, color: Colors.white, size: 28),
                label: const Text(
                  "Let's Hire",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
              ),
              const SizedBox(height: 12),

              // or other logins
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to normal login
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(isCustomerMode: false),
                      ),
                    );
                  },
                  child: Text(
                    'or other logins',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 24/7 Support phone card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.headset_mic, color: Colors.green, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      '24/7 Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Need help hiring a driver? Call us anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        // Show phone in a snackbar (no url_launcher dependency)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📞 Call us at $_contactPhone'),
                            action: SnackBarAction(label: 'CALL', onPressed: () {}),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _contactPhone,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // How it works mini section
              Text(
                'How DAD Works',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),

              // 3 steps
              Row(
                children: [
                  const Expanded(
                    child: _StepCard(number: '1', label: 'Register', color: Colors.orange),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _StepCard(number: '2', label: 'Get Approved', color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _StepCard(number: '3', label: 'Get Home Safe', color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Step Card for "How DAD Works" section
// ============================================================
class _StepCard extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _StepCard({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}