import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/time_slot.dart';
import '/services/firebase_service.dart';
import '../data/repositories/time_slot_repository_impl.dart';
import '../domain/repositories/time_slot_repository.dart';

final timeSlotRepositoryProvider = Provider<ITimeSlotRepository>((ref) {
  return TimeSlotRepositoryImpl(ref.watch(firestoreProvider));
});

// All time slots from the database (including archived)
final allTimeSlotsProvider = StreamProvider<List<TimeSlot>>((ref) {
  return ref.watch(timeSlotRepositoryProvider).getTimeSlots();
});

// Filtered time slots (Active only)
final timeSlotsProvider = StreamProvider<List<TimeSlot>>((ref) {
  return ref.watch(timeSlotRepositoryProvider).getTimeSlots().map((slots) {
    return slots.where((slot) => slot.isActive).toList();
  });
});

final timeSlotServiceProvider = Provider((ref) => TimeSlotActionService(ref));

class TimeSlotActionService {
  final Ref _ref;
  TimeSlotActionService(this._ref);

  Future<void> addTimeSlot({
    required String startTime,
    required String endTime,
    required String label,
    DateTime? effectiveDate,
  }) {
    return _ref.read(timeSlotRepositoryProvider).addTimeSlot(
          startTime: startTime,
          endTime: endTime,
          label: label,
          isActive: true,
          effectiveDate: effectiveDate ?? DateTime.now(),
        );
  }

  Future<void> updateTimeSlot({
    required String id,
    required String startTime,
    required String endTime,
    required String label,
    required DateTime effectiveDate,
    bool isActive = true,
  }) async {
    final updatedTimeSlot = TimeSlot(
      id: id,
      startTime: startTime,
      endTime: endTime,
      label: label,
      isActive: isActive,
      effectiveDate: effectiveDate,
    );
    return _ref.read(timeSlotRepositoryProvider).updateTimeSlot(updatedTimeSlot);
  }

  Future<void> archiveTimeSlot(String id) {
    return _ref.read(timeSlotRepositoryProvider).archiveTimeSlot(id);
  }

  Future<void> unarchiveTimeSlot(String id) {
    return _ref.read(timeSlotRepositoryProvider).unarchiveTimeSlot(id);
  }

  Future<void> deleteTimeSlotPermanently(String id) {
    return _ref.read(timeSlotRepositoryProvider).deleteTimeSlotPermanently(id);
  }

  @Deprecated('Use archiveTimeSlot instead')
  Future<void> deleteTimeSlot(String id) {
    return archiveTimeSlot(id);
  }
}
