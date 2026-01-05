import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/data/repositories/schedule_template_repository_impl.dart';
import '/core/domain/repositories/schedule_template_repository.dart';
import '/core/models/schedule_template.dart';
import '/core/providers/session_providers.dart';
import '/services/firebase_service.dart';
import 'client_providers.dart';
import 'notification_providers.dart';
import 'time_slot_providers.dart';

final scheduleTemplateRepositoryProvider =
    Provider<IScheduleTemplateRepository>((ref) {
  return ScheduleTemplateRepositoryImpl(ref.watch(firestoreProvider));
});

final scheduleTemplateProvider =
    StreamProvider.autoDispose.family<ScheduleTemplate?, String>((ref, clientId) {
  return ref
      .watch(scheduleTemplateRepositoryProvider)
      .getScheduleTemplateByClientId(clientId);
});

final allScheduleTemplatesProvider = StreamProvider<List<ScheduleTemplate>>((
  ref,
) {
  final repository = ref.watch(scheduleTemplateRepositoryProvider);
  if (repository is ScheduleTemplateRepositoryImpl) {
    // We need a stream of all templates to react to any change
    return ref
        .watch(firestoreProvider)
        .collection('schedule_templates')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduleTemplate.fromFirestore(doc))
              .toList(),
        );
  }
  // Fallback if repository doesn't support streaming all
  return Stream.fromFuture(repository.getAllTemplates());
});

final scheduleTemplateServiceProvider = Provider(
  (ref) => ScheduleTemplateActionService(ref),
);

class ScheduleTemplateActionService {
  final Ref _ref;
  ScheduleTemplateActionService(this._ref);

  Future<void> setScheduleRule({
    required String clientId,
    required String dayOfWeek,
    required String timeSlotId,
    required String employeeId,
  }) async {
    final rule = ScheduleRule(
      dayOfWeek: dayOfWeek,
      timeSlotId: timeSlotId,
      employeeId: employeeId,
    );
    await _ref
        .read(scheduleTemplateRepositoryProvider)
        .setScheduleRule(clientId: clientId, rule: rule);
    _ref.invalidate(scheduleTemplateProvider(clientId));
    _ref.invalidate(scheduleViewProvider);
    _ref.invalidate(allScheduleTemplatesProvider);

    // Send Notification
    try {
      final client = _ref.read(clientByIdProvider(clientId)).value;
      final timeSlot = _ref
          .read(timeSlotsProvider)
          .value
          ?.firstWhere((s) => s.id == timeSlotId);

      _ref.read(notificationServiceProvider).sendToUser(
            userId: employeeId,
            collection: 'employees',
            title: 'New Schedule Assigned',
            body:
                'You have been assigned to ${client?.name ?? 'a client'} on ${dayOfWeek}s at ${timeSlot?.label ?? 'the scheduled time'}.',
          );
    } catch (_) {}
  }

  Future<void> removeScheduleRule({
    required String clientId,
    required ScheduleRule ruleToRemove,
  }) async {
    await _ref
        .read(scheduleTemplateRepositoryProvider)
        .removeScheduleRule(clientId: clientId, rule: ruleToRemove);
    _ref.invalidate(scheduleTemplateProvider(clientId));
    _ref.invalidate(scheduleViewProvider);
    _ref.invalidate(allScheduleTemplatesProvider);

    // Send Notification
    try {
      final client = _ref.read(clientByIdProvider(clientId)).value;
      final timeSlot = _ref
          .read(timeSlotsProvider)
          .value
          ?.firstWhere((s) => s.id == ruleToRemove.timeSlotId);

      _ref.read(notificationServiceProvider).sendToUser(
            userId: ruleToRemove.employeeId,
            collection: 'employees',
            title: 'Schedule Removed',
            body:
                'Your assignment with ${client?.name ?? 'a client'} on ${ruleToRemove.dayOfWeek}s at ${timeSlot?.label ?? 'the scheduled time'} has been removed.',
          );
    } catch (_) {}
  }
}
