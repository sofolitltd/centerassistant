import 'package:flutter/foundation.dart';
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

final schedulableDepartmentsProvider = StreamProvider<Set<String>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('departments')
      .where('isSchedulable', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => doc.data()['name'] as String).toSet(),
      );
});

final nextEmployeeIdProvider = FutureProvider.autoDispose<String>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  // 1. Try to find the latest employee by createdAt (most reliable for sequence)
  try {
    final snapshot = await firestore
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final ids = snapshot.docs
          .map((doc) => doc.data()['employeeId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      if (ids.isNotEmpty) return _findNextIncrementalId(ids);
    }
  } catch (e) {
    debugPrint('Error fetching nextEmployeeId by createdAt: $e');
  }

  // 2. Try by employeeId descending (lexicographical fallback)
  try {
    final snapshot = await firestore
        .collection('employees')
        .orderBy('employeeId', descending: true)
        .limit(10)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final ids = snapshot.docs
          .map((doc) => doc.data()['employeeId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      if (ids.isNotEmpty) return _findNextIncrementalId(ids);
    }
  } catch (e) {
    debugPrint('Error fetching nextEmployeeId by employeeId: $e');
  }

  // 3. Fallback to counter if collection query failed or returned no IDs
  final doc = await firestore.collection('counters').doc('employees').get();
  if (doc.exists) {
    final count = (doc.data()?['count'] as int? ?? 0) + 1;
    return count.toString().padLeft(4, '0');
  }

  return '0001';
});

String _findNextIncrementalId(List<String> existingIds) {
  String? bestId;
  int maxVal = -1;

  for (final id in existingIds) {
    // Find numeric suffix
    final RegExp regExp = RegExp(r'(\d+)$');
    final match = regExp.firstMatch(id);
    if (match != null) {
      final val = int.tryParse(match.group(1)!) ?? -1;
      if (val > maxVal) {
        maxVal = val;
        bestId = id;
      }
    }
  }

  if (bestId == null) return _incrementId(existingIds.first);
  return _incrementId(bestId);
}

String _incrementId(String lastId) {
  if (lastId.isEmpty) return '0001';

  final RegExp regExp = RegExp(r'(\d+)$');
  final match = regExp.firstMatch(lastId);

  if (match != null) {
    final String numericPart = match.group(1)!;
    final int nextValue = int.parse(numericPart) + 1;
    final String prefix = lastId.substring(
      0,
      lastId.length - numericPart.length,
    );
    return prefix + nextValue.toString().padLeft(numericPart.length, '0');
  }

  return '${lastId}01';
}

// Model for Designation with Department link
class Designation {
  final String name;
  final String department;
  Designation({required this.name, required this.department});
}

final allDesignationsProvider = StreamProvider<List<Designation>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('designations')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => Designation(
                name: doc['name'] as String,
                department: doc['department'] as String? ?? '',
              ),
            )
            .toList(),
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
    final firestore = _ref.read(firestoreProvider);

    // 1. Check for duplicate ID
    final duplicate = await firestore
        .collection('employees')
        .where('employeeId', isEqualTo: employeeId)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('Employee ID "$employeeId" already exists.');
    }

    // 2. Perform addition
    await _ref
        .read(employeeRepositoryProvider)
        .addEmployee(
          employeeId: employeeId,
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

    // 3. Refresh next ID state
    _ref.invalidate(nextEmployeeIdProvider);
  }

  Future<void> updateEmployee(Employee employee) {
    return _ref.read(employeeRepositoryProvider).updateEmployee(employee);
  }

  Future<void> deleteEmployee(String id) {
    return _ref.read(employeeRepositoryProvider).deleteEmployee(id);
  }
}
