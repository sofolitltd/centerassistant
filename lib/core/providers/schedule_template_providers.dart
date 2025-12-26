import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/data/repositories/schedule_template_repository_impl.dart';
import '/core/domain/repositories/schedule_template_repository.dart';
import '/core/models/schedule_template.dart';
import '/core/providers/session_providers.dart';
import '/services/firebase_service.dart';

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
