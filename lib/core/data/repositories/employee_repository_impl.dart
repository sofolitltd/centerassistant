import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/employee.dart';
import '../../domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements IEmployeeRepository {
  final FirebaseFirestore _firestore;

  EmployeeRepositoryImpl(this._firestore);

  String _generateRandomPassword([int length = 8]) {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => charset[random.nextInt(charset.length)],
    ).join();
  }

  @override
  Stream<List<Employee>> getEmployees() {
    return _firestore
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Employee.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
        });
  }

  @override
  Stream<Employee?> getEmployeeById(String id) {
    return _firestore.collection('employees').doc(id).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return Employee.fromFirestore(snapshot);
      }
      return null;
    });
  }

  @override
  Stream<List<String>> getDepartments() {
    return _firestore.collection('departments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    });
  }

  @override
  Future<void> addEmployee({
    required String name,
    required String personalPhone,
    required String officialPhone,
    required String personalEmail,
    required String officialEmail,
    required String department,
    required String email,
    String? password,
  }) async {
    final counterRef = _firestore.collection('counters').doc('employees');

    return _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);

      int newIdNumber;
      if (!counterSnapshot.exists) {
        newIdNumber = 1;
      } else {
        final data = counterSnapshot.data();
        newIdNumber = (data?['count'] as int? ?? 0) + 1;
      }

      final newId = 't${newIdNumber.toString().padLeft(4, '0')}';

      final newEmployeeRef = _firestore.collection('employees').doc(newId);

      // Generate random password if not provided
      final finalPassword = (password == null || password.isEmpty)
          ? _generateRandomPassword()
          : password;

      final newEmployee = Employee(
        id: newId,
        name: name,
        personalPhone: personalPhone,
        officialPhone: officialPhone,
        personalEmail: personalEmail,
        officialEmail: officialEmail,
        department: department,
        email: email,
        password: finalPassword,
        mustChangePassword: true, // Always force change for new accounts
        joinDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      transaction.set(newEmployeeRef, newEmployee.toJson());
      transaction.set(counterRef, {'count': newIdNumber});
    });
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _firestore
        .collection('employees')
        .doc(employee.id)
        .update(employee.toJson());
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _firestore.collection('employees').doc(id).delete();
  }
}
