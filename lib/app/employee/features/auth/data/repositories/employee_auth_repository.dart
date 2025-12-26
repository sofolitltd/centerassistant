import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/employee.dart';

class EmployeeAuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Employee?> login(String email, String password) async {
    final snapshot = await _firestore
        .collection('employees')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final employee = Employee.fromFirestore(snapshot.docs.first);
      // Check if employee account is active
      if (!employee.isActive) {
        return null; // Account is blocked
      }
      return employee;
    }
    return null;
  }

  Future<void> changePassword(String userId, String newPassword) async {
    await _firestore.collection('employees').doc(userId).update({
      'password': newPassword,
      'mustChangePassword': false,
    });
  }

  Future<void> changeEmail(String userId, String newEmail) async {
    await _firestore.collection('employees').doc(userId).update({
      'email': newEmail,
    });
  }

  Future<void> logout() async {
    // Currently no persistence logic for employee role, matches admin structure
  }
}
