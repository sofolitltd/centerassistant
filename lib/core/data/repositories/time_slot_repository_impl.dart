import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class TimeSlotRepositoryImpl implements ITimeSlotRepository {
  final FirebaseFirestore _firestore;

  TimeSlotRepositoryImpl(this._firestore);

  @override
  Stream<List<TimeSlot>> getTimeSlots() {
    return _firestore.collection('time_slots').orderBy('id').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => TimeSlot.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    });
  }

  @override
  Future<void> addTimeSlot({
    required String startTime,
    required String endTime,
    required String label,
  }) async {
    final counterRef = _firestore.collection('counters').doc('time_slots');

    return _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);

      int newIdNumber;
      if (!counterSnapshot.exists) {
        newIdNumber = 1;
      } else {
        final data = counterSnapshot.data();
        newIdNumber = (data?['count'] as int? ?? 0) + 1;
      }

      final newId = 'ts${newIdNumber.toString().padLeft(4, '0')}';

      final newTimeSlotRef = _firestore.collection('time_slots').doc(newId);

      final newTimeSlot = TimeSlot(
        id: newId,
        startTime: startTime,
        endTime: endTime,
        label: label,
      );

      transaction.set(newTimeSlotRef, newTimeSlot.toJson());
      transaction.set(counterRef, {'count': newIdNumber});
    });
  }

  @override
  Future<void> updateTimeSlot(TimeSlot timeSlot) async {
    await _firestore
        .collection('time_slots')
        .doc(timeSlot.id)
        .update(timeSlot.toJson());
  }

  @override
  Future<void> deleteTimeSlot(String id) async {
    await _firestore.collection('time_slots').doc(id).delete();
  }
}
