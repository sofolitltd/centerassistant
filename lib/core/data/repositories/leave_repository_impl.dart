import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:center_assistant/core/models/leave.dart';
import 'package:center_assistant/core/domain/repositories/leave_repository.dart';

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
  Future<void> updateLeaveStatus(
    String leaveId,
    LeaveStatus status,
    String adminId,
  ) async {
    await _firestore.collection('leaves').doc(leaveId).update({
      'status': status.name,
      'approvedBy': adminId,
    });
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
          
          // Fix: Proper descending sort (Newest date first)
          leaves.sort((a, b) => b.date.compareTo(a.date));
          
          return leaves;
        });
  }
}
