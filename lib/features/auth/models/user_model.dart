// ============================================================
// User Model
// ============================================================
// Represents a user in the DAD system.
// ============================================================

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? initials;
  final String? dob;
  final String? nic;
  final String phone;
  final String role;
  final String status;
  final String? tempPassword;
  final bool mustChangePassword;
  final Map<String, dynamic>? customerProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.initials,
    this.dob,
    this.nic,
    required this.phone,
    required this.role,
    required this.status,
    this.tempPassword,
    this.mustChangePassword = false,
    this.customerProfile,
  });

  /// Returns true if the customer's profile is complete:
  /// Has location, vehicle type, vehicle number, and an email.
  /// Used to show the "Complete Your Profile" notification.
  bool get profileComplete {
    if (role != 'CUSTOMER') return true;
    final cp = customerProfile;
    if (cp == null) return false;
    final location = (cp['location'] as String?)?.trim() ?? '';
    final vehicleType = (cp['vehicleType'] as String?)?.trim() ?? '';
    final vehicleNumber = (cp['vehicleNumber'] as String?)?.trim() ?? '';
    final emailOk = email.trim().isNotEmpty && !email.startsWith('user_');
    return location.isNotEmpty && vehicleType.isNotEmpty && vehicleNumber.isNotEmpty && emailOk;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      initials: json['initials'],
      dob: json['dob'],
      nic: json['nic'],
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      tempPassword: json['tempPassword'],
      mustChangePassword: json['mustChangePassword'] ?? false,
      customerProfile: json['customerProfile'] as Map<String, dynamic>?,
    );
  }
}

class AuthResult {
  final UserModel user;
  final String token;
  final String? tempPassword;

  AuthResult({required this.user, required this.token, this.tempPassword});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: UserModel.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
      tempPassword: json['tempPassword'],
    );
  }
}