// ============================================================
// Home Screen - Role-Based Dashboard
// ============================================================
// Shows different dashboard based on user role:
//   - Driver: view rides
//   - Rider: book a ride
//   - Customer: request a driver
//   - Admin: manage system
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'request_driver_screen.dart';
import 'my_rides_screen.dart';
import '../widgets/rate_table_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final role = auth.role;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(AppConstants.appName),
        actions: [
          if (role == UserRole.customer)
            // Profile avatar at top-right (replaces logout icon position)
            GestureDetector(
              onTap: () => _showCustomerProfile(context, user?.fullName ?? '', role),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.fullName ?? '').isEmpty ? '?' : user!.fullName![0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
        ],
      ),
      drawer: _buildDrawer(context, user?.fullName ?? '', role),
      body: _buildRoleDashboard(role, user?.fullName ?? ''),
    );
  }

  Widget _buildDrawer(BuildContext context, String name, String role) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.indigo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 36, color: Colors.indigo),
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Role: $role',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCustomerProfile(BuildContext context, String fullName, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.indigo,
                child: Text(
                  fullName.isEmpty ? '?' : fullName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Role: $role', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.orange),
                title: const Text('My Vehicle'),
                subtitle: const Text('Vehicle details'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                subtitle: const Text('Sign out of your account'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final auth = context.read<AuthProvider>();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDashboard(String role, String name) {
    switch (role) {
      case UserRole.driver:
        return _DriverDashboard(name: name);
      case UserRole.rider:
        return _RiderDashboard(name: name);
      case UserRole.customer:
        return _CustomerDashboard(name: name);
      case UserRole.admin:
        return _AdminDashboard(name: name);
      default:
        return _PendingDashboard(name: name);
    }
  }
}

// ============================================================
// Driver Dashboard
// ============================================================
class _DriverDashboard extends StatelessWidget {
  final String name;
  const _DriverDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $name 🚗',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Driver Portal',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _DashboardCard(
                  icon: Icons.route,
                  title: 'My Rides',
                  subtitle: 'Confirmed rides (both accepted)',
                  color: Colors.indigo,
                  onTap: () {
                    // My Rides: only upcoming/ongoing rides (NOT completed — those go to History)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRidesScreen(statusFilter: 'UPCOMING,ONGOING')),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.event_available,
                  title: 'Upcoming',
                  subtitle: 'Pending tickets only',
                  color: Colors.orange,
                  onTap: () {
                    // Only pending tickets (ASSIGNED). Once both accept → UPCOMING → My Rides.
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRidesScreen(statusFilter: 'ASSIGNED')),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'Completed & cancelled rides',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRidesScreen(statusFilter: 'COMPLETED,PENDING_REQUEST')),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'My details',
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Rider Dashboard
// ============================================================
class _RiderDashboard extends StatelessWidget {
  final String name;
  const _RiderDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $name 🙋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Rider Portal',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _DashboardCard(
                  icon: Icons.route,
                  title: 'My Rides',
                  subtitle: 'Confirmed rides (both accepted)',
                  color: Colors.indigo,
                  onTap: () {
                    // Only confirmed rides (both accepted → UPCOMING) show in My Rides
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRidesScreen(role: 'rider', statusFilter: 'UPCOMING,ONGOING')),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.event_available,
                  title: 'Upcoming Rides',
                  subtitle: 'Pending tickets only',
                  color: Colors.orange,
                  onTap: () {
                    // Only pending tickets (ASSIGNED). Once both accept → UPCOMING → My Rides.
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRidesScreen(role: 'rider', statusFilter: 'ASSIGNED')),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.history,
                  title: 'Completed',
                  subtitle: 'Ride history',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRidesScreen(role: 'rider', statusFilter: 'COMPLETED,PENDING_REQUEST')),
                    );
                  },
                ),
                const _DashboardCard(
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'My details',
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Customer Dashboard
// ============================================================
class _CustomerDashboard extends StatelessWidget {
  final String name;
  const _CustomerDashboard({required this.name});

  // We read the contact phone from the rate card (which fetches /api/rates).
  // For dial, use url_launcher via a simple approach — but to avoid adding deps,
  // store phone and let the rate card parse it. We'll refetch here with a small helper.
  static Future<String?> _fetchContactPhone() async {
    try {
      final res = await ApiClient.instance.get('/api/rates');
      return res['data']['rate']?['contactPhone'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _openProfile(BuildContext context, String fullName, String role) {
    // Profile screen: shows avatar circle with first letter, logout, my vehicle.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.indigo,
                child: Text(
                  fullName.isEmpty ? '?' : fullName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Role: $role', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              // My Vehicle feature inside profile
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.orange),
                title: const Text('My Vehicle'),
                subtitle: const Text('Vehicle details'),
                onTap: () => Navigator.pop(ctx),
              ),
              // Logout inside profile
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                subtitle: const Text('Sign out of your account'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final auth = context.read<AuthProvider>();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome, $name 👤',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Customer Portal',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),

          // Rate Table FIRST — prominent, full width
          const RateTableCard(),
          const SizedBox(height: 20),

          // Request Driver — FULL WIDTH button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestDriverScreen()),
              );
            },
            icon: const Icon(Icons.airport_shuttle, color: Colors.white),
            label: const Text('Request Driver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),

          // Call Us — FULL WIDTH button (admin-set number from /api/rates contactPhone)
          FutureBuilder<String?>(
            future: _fetchContactPhone(),
            builder: (ctx, snap) {
              final phone = snap.data ?? '0763003678';
              return ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📞 Call us at $phone'),
                      action: SnackBarAction(label: 'CALL', onPressed: () {}),
                    ),
                  );
                },
                icon: const Icon(Icons.call, color: Colors.white),
                label: Text('Call Us  $phone', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Admin Dashboard
// ============================================================
class _AdminDashboard extends StatelessWidget {
  final String name;
  const _AdminDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, $name 📊',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Admin Portal',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: const [
                _DashboardCard(
                  icon: Icons.directions_car,
                  title: 'Drivers',
                  subtitle: 'Manage drivers',
                  color: Colors.indigo,
                ),
                _DashboardCard(
                  icon: Icons.person_pin,
                  title: 'Riders',
                  subtitle: 'Manage riders',
                  color: Colors.orange,
                ),
                _DashboardCard(
                  icon: Icons.local_taxi,
                  title: 'Customers',
                  subtitle: 'Manage customers',
                  color: Colors.green,
                ),
                _DashboardCard(
                  icon: Icons.route,
                  title: 'Rides',
                  subtitle: 'Manage rides',
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Pending Approval Dashboard
// ============================================================
class _PendingDashboard extends StatelessWidget {
  final String name;
  const _PendingDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Welcome, $name',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your account is pending admin approval.\nPlease wait for the administrator to review your registration.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Small Action Button — compact card for secondary actions
// ============================================================
class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SmallAction({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      ),
    );
  }
}

// ============================================================
// Dashboard Card
// ============================================================
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}