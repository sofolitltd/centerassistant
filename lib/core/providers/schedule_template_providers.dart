import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/data/repositories/schedule_template_repository_impl.dart';
import '/core/domain/repositories/schedule_template_repository.dart';
import '/core/models/schedule_template.dart';
import '/core/providers/session_providers.dart';
import '/services/firebase_service.dart';
import 'client_providers.dart';
import 'notification_providers.dart';

final scheduleTemplateRepositoryProvider =
    Provider<IScheduleTemplateRepository>((ref) {
      return ScheduleTemplateRepositoryImpl(ref.watch(firestoreProvider));
    });

final scheduleTemplateProvider = StreamProvider.autoDispose
    .family<ScheduleTemplate?, String>((ref, clientId) {
      return ref
          .watch(scheduleTemplateRepositoryProvider)
          .getScheduleTemplateByClientId(clientId);
    });

final allScheduleTemplatesProvider = StreamProvider<List<ScheduleTemplate>>((
  ref,
) {
  final repository = ref.watch(scheduleTemplateRepositoryProvider);
  if (repository is ScheduleTemplateRepositoryImpl) {
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
    required String timeSlotId,
    required String employeeId,
    required String serviceType,
    required String startTime,
    required String endTime,
    required RecurrenceFrequency frequency,
    required int interval,
    required List<String> daysOfWeek,
    required RecurrenceEndType endType,
    DateTime? untilDate,
    int? occurrences,
    int? dayOfMonth,
    DateTime? startDate,
  }) async {
    final rule = ScheduleRule(
      timeSlotId: timeSlotId,
      employeeId: employeeId,
      serviceType: serviceType,
      startTime: startTime,
      endTime: endTime,
      frequency: frequency,
      interval: interval,
      daysOfWeek: daysOfWeek,
      endType: endType,
      untilDate: untilDate,
      occurrences: occurrences,
      dayOfMonth: dayOfMonth,
      startDate: startDate,
    );
    await _ref
        .read(scheduleTemplateRepositoryProvider)
        .setScheduleRule(clientId: clientId, rule: rule);
    _ref.invalidate(scheduleTemplateProvider(clientId));
    _ref.invalidate(scheduleViewProvider);
    _ref.invalidate(allScheduleTemplatesProvider);

    // Notification Logic
    try {
      final client = _ref.read(clientByIdProvider(clientId)).value;
      _ref
          .read(notificationServiceProvider)
          .sendToUser(
            userId: employeeId,
            collection: 'employees',
            title: 'New Schedule Assigned',
            body:
                'You have been assigned to ${client?.name ?? 'a client'} with a ${frequency.name} recurrence.',
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
  }
}
