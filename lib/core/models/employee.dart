import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id; // Random Document ID
  final String employeeId; // Sequential ID (e.g., 0001)
  final String name;
  final String nickName;
  final String personalPhone;
  final String officialPhone;
  final String personalEmail;
  final String officialEmail;
  final String department;
  final String designation;
  final String gender;
  final DateTime? dateOfBirth;
  final String email;
  final String password;
  final String role;
  final bool mustChangePassword;
  final bool isActive;
  final DateTime joinedDate;
  final DateTime createdAt;
  final String image;
  final int carriedForwardLeaves;
  final String? fcmToken;

  Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.department,
    this.nickName = '',
    this.personalPhone = '',
    this.officialPhone = '',
    this.personalEmail = '',
    this.officialEmail = '',
    this.designation = '',
    this.gender = 'male',
    this.dateOfBirth,
    this.email = '',
    this.password = '',
    this.role = 'employee',
    this.mustChangePassword = false,
    this.isActive = true,
    required this.joinedDate,
    required this.createdAt,
    this.image = '',
    this.carriedForwardLeaves = 0,
    this.fcmToken,
  });

  bool get hasPortalAccess =>
      email.isNotEmpty && password.isNotEmpty && isActive;

  Employee copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? nickName,
    String? personalPhone,
    String? officialPhone,
    String? personalEmail,
    String? officialEmail,
    String? department,
    String? designation,
    String? gender,
    DateTime? dateOfBirth,
    String? email,
    String? password,
    String? role,
    bool? mustChangePassword,
    bool? isActive,
    DateTime? joinedDate,
    DateTime? createdAt,
    String? image,
    int? carriedForwardLeaves,
    String? fcmToken,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      nickName: nickName ?? this.nickName,
      personalPhone: personalPhone ?? this.personalPhone,
      officialPhone: officialPhone ?? this.officialPhone,
      personalEmail: personalEmail ?? this.personalEmail,
      officialEmail: officialEmail ?? this.officialEmail,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      image: image ?? this.image,
      carriedForwardLeaves: carriedForwardLeaves ?? this.carriedForwardLeaves,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'name': name,
      'nickName': nickName,
      'personalPhone': personalPhone,
      'officialPhone': officialPhone,
      'personalEmail': personalEmail,
      'officialEmail': officialEmail,
      'department': department,
      'designation': designation,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'email': email,
      'password': password,
      'role': role,
      'mustChangePassword': mustChangePassword,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'image': image,
      'carriedForwardLeaves': carriedForwardLeaves,
      'fcmToken': fcmToken,
    };
  }

  factory Employee.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Employee(
      id: snapshot.id,
      employeeId: data['employeeId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      nickName: data['nickName'] as String? ?? '',
      personalPhone: data['personalPhone'] as String? ?? '',
      officialPhone: data['officialPhone'] as String? ?? '',
      personalEmail: data['personalEmail'] as String? ?? '',
      officialEmail: data['officialEmail'] as String? ?? '',
      department: data['department'] as String? ?? '',
      designation: data['designation'] as String? ?? '',
      gender: data['gender'] as String? ?? 'male',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      joinedDate:
          (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      mustChangePassword: data['mustChangePassword'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      image: data['image'] as String? ?? '',
      carriedForwardLeaves: data['carriedForwardLeaves'] as int? ?? 0,
      fcmToken: data['fcmToken'] as String?,
    );
  }
}
