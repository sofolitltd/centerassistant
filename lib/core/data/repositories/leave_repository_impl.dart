import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/leave.dart';
import '../../domain/repositories/leave_repository.dart';

class LeaveRepositoryImpl implements ILeaveRepository {
  final FirebaseFirestore _firestore;

  LeaveRepositoryImpl(this._firestore);

  @override
  Future<void> addLeave(Leave leave) async {
    await _firestore.collection('leaves').doc(leave.id).set(leave.toJson());
  }

  @override
  Future<void> removeLeave(String leaveId) async {
    await _firestore.collection('leaves').doc(leaveId).delete();
  }

  @override
  Stream<List<Leave>> getLeavesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('leaves')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Leave.fromFirestore(doc)).toList(),
        );
  }

  @override
  Stream<List<Leave>> getLeavesByEntity(String entityId) {
    return _firestore
        .collection('leaves')
        .where('entityId', isEqualTo: entityId)
        .snapshots()
        .map((snapshot) {
          final leaves = snapshot.docs
              .map((doc) => Leave.fromFirestore(doc))
              .toList();
          leaves.sort((a, b) => b.date.compareTo(a.date));
          return leaves;
        });
  }
}
