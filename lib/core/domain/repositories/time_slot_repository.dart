import '/core/models/time_slot.dart';

abstract class ITimeSlotRepository {
  Stream<List<TimeSlot>> getTimeSlots();
  Future<void> addTimeSlot({
    required String startTime,
    required String endTime,
    required String label,
  });
  Future<void> updateTimeSlot(TimeSlot timeSlot);
  Future<void> deleteTimeSlot(String id);
}
