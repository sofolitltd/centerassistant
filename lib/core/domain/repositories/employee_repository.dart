import '/core/models/employee.dart';

abstract class IEmployeeRepository {
  Stream<List<Employee>> getEmployees();
  Stream<Employee?> getEmployeeById(String id);
  Stream<List<String>> getDepartments();
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
  });
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
}
