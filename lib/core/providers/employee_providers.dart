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

final employeeServiceProvider = Provider((ref) => EmployeeActionService(ref));

class EmployeeActionService {
  final Ref _ref;
  EmployeeActionService(this._ref);

  Future<void> addEmployee({
    required String name,
    required String personalPhone,
    required String officialPhone,
    required String personalEmail,
    required String officialEmail,
    required String department,
    required String email,
    String? password,
  }) {
    return _ref
        .read(employeeRepositoryProvider)
        .addEmployee(
          name: name,
          personalPhone: personalPhone,
          officialPhone: officialPhone,
          personalEmail: personalEmail,
          officialEmail: officialEmail,
          department: department,
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
