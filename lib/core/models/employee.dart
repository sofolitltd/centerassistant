import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String name;
  final String personalPhone;
  final String officialPhone;
  final String personalEmail;
  final String officialEmail;
  final String department;
  final String email;
  final String password;
  final String role;
  final bool mustChangePassword;
  final bool isActive; // Can user login? Toggle to block/unblock instantly
  final DateTime joinDate;
  final DateTime createdAt;
  final String image;

  Employee({
    required this.id,
    required this.name,
    this.personalPhone = '',
    this.officialPhone = '',
    this.personalEmail = '',
    this.officialEmail = '',
    this.department = '',
    required this.email,
    this.password = '',
    this.role = 'employee',
    this.mustChangePassword = false,
    this.isActive = true, // Active by default
    required this.joinDate,
    required this.createdAt,
    this.image = '',
  });

  // Helper getter to check if employee has portal access
  bool get hasPortalAccess =>
      email.isNotEmpty && password.isNotEmpty && isActive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'personalPhone': personalPhone,
      'officialPhone': officialPhone,
      'personalEmail': personalEmail,
      'officialEmail': officialEmail,
      'department': department,
      'email': email,
      'password': password,
      'role': role,
      'mustChangePassword': mustChangePassword,
      'isActive': isActive,
      'joinDate': Timestamp.fromDate(joinDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'image': image,
    };
  }

  factory Employee.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Employee(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Unnamed Employee',
      personalPhone: data['personalPhone'] as String? ?? '',
      officialPhone: data['officialPhone'] as String? ?? '',
      personalEmail: data['personalEmail'] as String? ?? '',
      officialEmail: data['officialEmail'] as String? ?? '',
      department: data['department'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      mustChangePassword: data['mustChangePassword'] as bool? ?? false,
      isActive:
          data['isActive'] as bool? ??
          true, // Default to active for backward compatibility
      joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      image: data['image'] as String? ?? '',
    );
  }
}
