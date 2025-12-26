import '/core/models/employee.dart';

abstract class IEmployeeRepository {
  Stream<List<Employee>> getEmployees();
  Stream<Employee?> getEmployeeById(String id);
  Stream<List<String>> getDepartments();
  Future<void> addEmployee({
    required String name,
    required String personalPhone,
    required String officialPhone,
    required String personalEmail,
    required String officialEmail,
    required String department,
    required String email,
    String? password,
  });
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
}
