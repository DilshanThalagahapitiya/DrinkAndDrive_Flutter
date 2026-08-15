// ============================================================
// Login Screen
// ============================================================
// User login with email + password or Google Sign-In.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/auth/google_auth_service.dart';
import '../providers/auth_provider.dart';
import '../../../features/home/screens/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isCustomerMode;
  const LoginScreen({super.key, this.isCustomerMode = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _keepLoggedIn = true; // Keep me logged in — default ON for all roles
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    debugPrint('🟢 [LoginScreen] _googleSignIn called');
    if (mounted) {
      setState(() => _googleLoading = true);
    }
    try {
      final account = await GoogleAuthService.instance.signIn();
      if (account == null) {
        debugPrint('⚠️ [LoginScreen] User cancelled Google sign-in');
        return;
      }
      debugPrint('🟢 [LoginScreen] Google account: ${account.email}');

      final idToken = await GoogleAuthService.instance.getIdToken();
      if (idToken == null) {
        debugPrint('❌ [LoginScreen] ID token is null');
        throw Exception('Could not obtain Google ID token');
      }
      debugPrint('🟢 [LoginScreen] Got ID token (${idToken.length} chars), sending to backend...');

      final auth = context.read<AuthProvider>();
      final success = await auth.googleSignIn(idToken, role: 'CUSTOMER');
      debugPrint('🟢 [LoginScreen] Backend result: success=$success');
      if (!mounted) return;
      if (success) {
        debugPrint('✅ [LoginScreen] Google sign-in successful, navigating to Home');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        debugPrint('❌ [LoginScreen] Backend rejected: ${auth.error}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google sign-in failed: ${auth.error ?? "Unknown error"}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('❌ [LoginScreen] EXCEPTION during Google sign-in: $e');
      debugPrint('❌ [LoginScreen] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      keepLoggedIn: _keepLoggedIn,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'D',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        widget.isCustomerMode ? 'Hire a Driver' : '${AppConstants.appName} - Login',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isCustomerMode ? 'Login to hire a safe driver' : AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 28),

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

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your email'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter your password'
                            : null,
                      ),
                      const SizedBox(height: 8),

                      // Keep me logged in (applies to all roles)
                      CheckboxListTile(
                        value: _keepLoggedIn,
                        onChanged: (v) => setState(() => _keepLoggedIn = v ?? true),
                        title: const Text('Keep me logged in',
                            style: TextStyle(fontSize: 14)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 8),

                      // Login button
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 16),

                      // Sign up link — customers go directly to customer signup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('New here? ',
                              style: TextStyle(color: Colors.grey.shade600)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SignupScreen(
                                      initialRole: widget.isCustomerMode ? 'customer' : null,
                                    )),
                              );
                            },
                            child: const Text('Register',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}