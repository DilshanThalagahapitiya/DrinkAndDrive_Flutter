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
  });

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