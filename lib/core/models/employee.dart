import 'package:cloud_firestore/cloud_firestore.dart';

class Education {
  final String institute;
  final String degree;
  final String passingYear;

  Education({
    required this.institute,
    required this.degree,
    required this.passingYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'institute': institute,
      'degree': degree,
      'passingYear': passingYear,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institute: json['institute'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      passingYear: json['passingYear'] as String? ?? '',
    );
  }
}

class Employee {
  // --- 1. Basic Information ---
  final String id; // Random Document ID
  final String employeeId; // Sequential ID (e.g., 0001)
  final String name;
  final String nickName;
  final String gender;
  final DateTime? dateOfBirth;
  final String image;
  final String nid;
  final String tin;

  // --- 2. Contact Information ---
  final String personalPhone;
  final String officialPhone;
  final String personalEmail;
  final String officialEmail;
  final String presentAddress;
  final String permanentAddress;

  // --- 3. Professional & Education ---
  final String department;
  final String designation;
  final List<Education> education;

  // --- 4. Employment & Separation ---
  final DateTime joinedDate;
  final DateTime? separationDate;
  final bool isActive;

  // --- System & Auth ---
  final String email;
  final String password;
  final String role;
  final bool mustChangePassword;
  final DateTime createdAt;
  final int carriedForwardLeaves;
  final String? fcmToken;

  Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    this.nickName = '',
    this.gender = 'male',
    this.dateOfBirth,
    this.image = '',
    this.nid = '',
    this.tin = '',
    this.personalPhone = '',
    this.officialPhone = '',
    this.personalEmail = '',
    this.officialEmail = '',
    this.presentAddress = '',
    this.permanentAddress = '',
    required this.department,
    this.designation = '',
    this.education = const [],
    required this.joinedDate,
    this.separationDate,
    this.isActive = true,
    this.email = '',
    this.password = '',
    this.role = 'employee',
    this.mustChangePassword = false,
    required this.createdAt,
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
    String? gender,
    DateTime? dateOfBirth,
    String? image,
    String? nid,
    String? tin,
    String? personalPhone,
    String? officialPhone,
    String? personalEmail,
    String? officialEmail,
    String? presentAddress,
    String? permanentAddress,
    String? department,
    String? designation,
    List<Education>? education,
    DateTime? joinedDate,
    DateTime? separationDate,
    bool? isActive,
    String? email,
    String? password,
    String? role,
    bool? mustChangePassword,
    DateTime? createdAt,
    int? carriedForwardLeaves,
    String? fcmToken,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      nickName: nickName ?? this.nickName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      image: image ?? this.image,
      nid: nid ?? this.nid,
      tin: tin ?? this.tin,
      personalPhone: personalPhone ?? this.personalPhone,
      officialPhone: officialPhone ?? this.officialPhone,
      personalEmail: personalEmail ?? this.personalEmail,
      officialEmail: officialEmail ?? this.officialEmail,
      presentAddress: presentAddress ?? this.presentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      education: education ?? this.education,
      joinedDate: joinedDate ?? this.joinedDate,
      separationDate: separationDate ?? this.separationDate,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      carriedForwardLeaves: carriedForwardLeaves ?? this.carriedForwardLeaves,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'name': name,
      'nickName': nickName,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'image': image,
      'nid': nid,
      'tin': tin,
      'personalPhone': personalPhone,
      'officialPhone': officialPhone,
      'personalEmail': personalEmail,
      'officialEmail': officialEmail,
      'presentAddress': presentAddress,
      'permanentAddress': permanentAddress,
      'department': department,
      'designation': designation,
      'education': education.map((e) => e.toJson()).toList(),
      'joinedDate': Timestamp.fromDate(joinedDate),
      'separationDate': separationDate != null
          ? Timestamp.fromDate(separationDate!)
          : null,
      'isActive': isActive,
      'email': email,
      'password': password,
      'role': role,
      'mustChangePassword': mustChangePassword,
      'createdAt': Timestamp.fromDate(createdAt),
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
      gender: data['gender'] as String? ?? 'male',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      image: data['image'] as String? ?? '',
      nid: data['nid'] as String? ?? '',
      tin: data['tin'] as String? ?? '',
      personalPhone: data['personalPhone'] as String? ?? '',
      officialPhone: data['officialPhone'] as String? ?? '',
      personalEmail: data['personalEmail'] as String? ?? '',
      officialEmail: data['officialEmail'] as String? ?? '',
      presentAddress: data['presentAddress'] as String? ?? '',
      permanentAddress: data['permanentAddress'] as String? ?? '',
      department: data['department'] as String? ?? '',
      designation: data['designation'] as String? ?? '',
      education:
          (data['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      joinedDate:
          (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      separationDate: (data['separationDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
      mustChangePassword: data['mustChangePassword'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      carriedForwardLeaves: data['carriedForwardLeaves'] as int? ?? 0,
      fcmToken: data['fcmToken'] as String?,
    );
  }
}
