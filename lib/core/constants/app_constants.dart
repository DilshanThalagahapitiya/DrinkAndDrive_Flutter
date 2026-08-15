// ============================================================
// App Constants
// ============================================================
// Central configuration for the DAD application.
// ============================================================

class AppConstants {
  // Backend API base URL (Next.js backend running on port 3000)
  static const String baseUrl = 'http://localhost:3000';
    // static const String baseUrl = 'https://endowment-slideshow-panorama.ngrok-free.dev';


  // App info
  static const String appName = 'DAD';
  static const String appTagline = 'Drink and Drive Safe';
}

// User roles
class UserRole {
  static const String admin = 'ADMIN';
  static const String driver = 'DRIVER';
  static const String rider = 'RIDER';
  static const String customer = 'CUSTOMER';
  static const String hotel = 'HOTEL';
}