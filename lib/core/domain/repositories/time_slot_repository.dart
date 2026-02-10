import '/core/models/time_slot.dart';

abstract class ITimeSlotRepository {
  Stream<List<TimeSlot>> getTimeSlots();
  Future<void> addTimeSlot({
    required String startTime,
    required String endTime,
    required String label,
    required bool isActive,
    required DateTime effectiveDate,
    DateTime? effectiveEndDate,
  });
  Future<void> updateTimeSlot(TimeSlot timeSlot);
  Future<void> archiveTimeSlot(String id);
  Future<void> unarchiveTimeSlot(String id);
  Future<void> deleteTimeSlotPermanently(String id);
}
