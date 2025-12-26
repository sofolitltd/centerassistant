import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/time_slot.dart';
import '/services/firebase_service.dart';
import '../data/repositories/time_slot_repository_impl.dart';
import '../domain/repositories/time_slot_repository.dart';

final timeSlotRepositoryProvider = Provider<ITimeSlotRepository>((ref) {
  return TimeSlotRepositoryImpl(ref.watch(firestoreProvider));
});

final timeSlotsProvider = StreamProvider<List<TimeSlot>>((ref) {
  return ref.watch(timeSlotRepositoryProvider).getTimeSlots();
});

final timeSlotServiceProvider = Provider((ref) => TimeSlotActionService(ref));

class TimeSlotActionService {
  final Ref _ref;
  TimeSlotActionService(this._ref);

  Future<void> addTimeSlot({
    required String startTime,
    required String endTime,
    required String label,
  }) {
    return _ref
        .read(timeSlotRepositoryProvider)
        .addTimeSlot(startTime: startTime, endTime: endTime, label: label);
  }

  Future<void> updateTimeSlot(TimeSlot timeSlot) {
    return _ref.read(timeSlotRepositoryProvider).updateTimeSlot(timeSlot);
  }

  Future<void> deleteTimeSlot(String id) {
    return _ref.read(timeSlotRepositoryProvider).deleteTimeSlot(id);
  }
}
