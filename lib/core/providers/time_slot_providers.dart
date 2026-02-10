import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/time_slot.dart';
import '/services/firebase_service.dart';
import '../data/repositories/time_slot_repository_impl.dart';
import '../domain/repositories/time_slot_repository.dart';

final timeSlotRepositoryProvider = Provider<ITimeSlotRepository>((ref) {
  return TimeSlotRepositoryImpl(ref.watch(firestoreProvider));
});

// All time slots from the database
final allTimeSlotsProvider = StreamProvider<List<TimeSlot>>((ref) {
  return ref.watch(timeSlotRepositoryProvider).getTimeSlots();
});

// Filtered time slots (Active only based on date)
final timeSlotsProvider = StreamProvider<List<TimeSlot>>((ref) {
  return ref.watch(timeSlotRepositoryProvider).getTimeSlots().map((slots) {
    return slots.where((slot) => slot.isActive).toList();
  });
});

// Get time slots valid for a specific date
final timeSlotsForDateProvider =
    StreamProvider.family<List<TimeSlot>, DateTime>((ref, date) {
      return ref.watch(timeSlotRepositoryProvider).getTimeSlots().map((slots) {
        return slots.where((slot) {
          if (!slot.isActive) return false;

          final effectiveStart = DateTime(
            slot.effectiveDate.year,
            slot.effectiveDate.month,
            slot.effectiveDate.day,
          );
          final checkDate = DateTime(date.year, date.month, date.day);

          if (checkDate.isBefore(effectiveStart)) return false;

          if (slot.effectiveEndDate != null) {
            final effectiveEnd = DateTime(
              slot.effectiveEndDate!.year,
              slot.effectiveEndDate!.month,
              slot.effectiveEndDate!.day,
            );
            if (checkDate.isAfter(effectiveEnd)) return false;
          }

          return true;
        }).toList();
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
    DateTime? effectiveEndDate,
  }) {
    return _ref
        .read(timeSlotRepositoryProvider)
        .addTimeSlot(
          startTime: startTime,
          endTime: endTime,
          label: label,
          isActive: true,
          effectiveDate: effectiveDate ?? DateTime.now(),
          effectiveEndDate: effectiveEndDate,
        );
  }

  Future<void> updateTimeSlot({
    required String id,
    required String startTime,
    required String endTime,
    required String label,
    required DateTime effectiveDate,
    DateTime? effectiveEndDate,
    bool isActive = true,
  }) async {
    final updatedTimeSlot = TimeSlot(
      id: id,
      startTime: startTime,
      endTime: endTime,
      label: label,
      isActive: isActive,
      effectiveDate: effectiveDate,
      effectiveEndDate: effectiveEndDate,
    );
    return _ref
        .read(timeSlotRepositoryProvider)
        .updateTimeSlot(updatedTimeSlot);
  }

  Future<void> deleteTimeSlotPermanently(String id) {
    return _ref.read(timeSlotRepositoryProvider).deleteTimeSlotPermanently(id);
  }
}
