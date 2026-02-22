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
    required String employeeId,
    required String name,
    String nickName = '',
    required String personalPhone,
    required String officialPhone,
    required String personalEmail,
    required String officialEmail,
    required String department,
    String designation = '',
    String gender = 'male',
    DateTime? dateOfBirth,
    required String email,
    String? password,
  }) async {
    final counterRef = _firestore.collection('counters').doc('employees');

    return _firestore.runTransaction((transaction) async {
      // 1. Generate a RANDOM document ID for Firestore
      final newEmployeeRef = _firestore.collection('employees').doc();
      final docId = newEmployeeRef.id;

      // Generate random password if not provided
      final finalPassword = (password == null || password.isEmpty)
          ? _generateRandomPassword()
          : password;

      final newEmployee = Employee(
        id: docId, // Firestore random ID
        employeeId: employeeId, // The provided ID
        name: name,
        nickName: nickName,
        personalPhone: personalPhone,
        officialPhone: officialPhone,
        personalEmail: personalEmail,
        officialEmail: officialEmail,
        department: department,
        designation: designation,
        gender: gender,
        dateOfBirth: dateOfBirth,
        email: email,
        password: finalPassword,
        mustChangePassword: true, // Always force change for new accounts
        joinedDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      transaction.set(newEmployeeRef, newEmployee.toJson());

      // 2. Sync the counter if the employeeId is numeric
      try {
        final numericId = int.parse(employeeId);
        transaction.set(counterRef, {
          'count': numericId,
        }, SetOptions(merge: true));
      } catch (_) {
        // Not numeric, skip counter update
      }
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
