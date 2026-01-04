import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/domain/repositories/employee_repository.dart';
import '/core/models/employee.dart';
import '/services/firebase_service.dart';
import '../data/repositories/employee_repository_impl.dart';

final employeeRepositoryProvider = Provider<IEmployeeRepository>((ref) {
  return EmployeeRepositoryImpl(ref.watch(firestoreProvider));
});

final employeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).getEmployees();
});

final employeeByIdProvider = StreamProvider.family<Employee?, String>((
  ref,
  id,
) {
  return ref.watch(employeeRepositoryProvider).getEmployeeById(id);
});

final departmentsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(employeeRepositoryProvider).getDepartments();
});

// Model for Designation with Department link
class Designation {
  final String name;
  final String department;
  Designation({required this.name, required this.department});
}

final allDesignationsProvider = StreamProvider<List<Designation>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('designations').snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Designation(
          name: doc['name'] as String,
          department: doc['department'] as String? ?? '',
        )).toList(),
      );
});

final designationsProvider = StreamProvider<List<String>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('designations')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => doc['name'] as String).toList(),
      );
});

final employeeServiceProvider = Provider((ref) => EmployeeActionService(ref));

class EmployeeActionService {
  final Ref _ref;
  EmployeeActionService(this._ref);

  Future<void> addEmployee({
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
  }) {
    return _ref
        .read(employeeRepositoryProvider)
        .addEmployee(
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
          password: password,
        );
  }

  Future<void> updateEmployee(Employee employee) {
    return _ref.read(employeeRepositoryProvider).updateEmployee(employee);
  }

  Future<void> deleteEmployee(String id) {
    return _ref.read(employeeRepositoryProvider).deleteEmployee(id);
  }
}
