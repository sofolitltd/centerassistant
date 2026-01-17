import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class TimeSlotRepositoryImpl implements ITimeSlotRepository {
  final FirebaseFirestore _firestore;

  TimeSlotRepositoryImpl(this._firestore);

  @override
  Stream<List<TimeSlot>> getTimeSlots() {
    return _firestore.collection('time_slots').snapshots().map((snapshot) {
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
    required bool isActive,
    required DateTime effectiveDate,
  }) async {
    final docRef = _firestore.collection('time_slots').doc();

    final newTimeSlot = TimeSlot(
      id: docRef.id,
      startTime: startTime,
      endTime: endTime,
      label: label,
      isActive: isActive,
      effectiveDate: effectiveDate,
    );

    await docRef.set(newTimeSlot.toJson());
  }

  @override
  Future<void> updateTimeSlot(TimeSlot timeSlot) async {
    await _firestore
        .collection('time_slots')
        .doc(timeSlot.id)
        .update(timeSlot.toJson());
  }

  @override
  Future<void> archiveTimeSlot(String id) async {
    await _firestore.collection('time_slots').doc(id).update({
      'isActive': false,
    });
  }

  @override
  Future<void> unarchiveTimeSlot(String id) async {
    await _firestore.collection('time_slots').doc(id).update({
      'isActive': true,
    });
  }

  @override
  Future<void> deleteTimeSlotPermanently(String id) async {
    await _firestore.collection('time_slots').doc(id).delete();
  }
}
