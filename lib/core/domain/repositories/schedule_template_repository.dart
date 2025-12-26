import '/core/models/schedule_template.dart';

abstract class IScheduleTemplateRepository {
  Stream<ScheduleTemplate?> getScheduleTemplateByClientId(String clientId);
  Future<void> setScheduleRule({
    required String clientId,
    required ScheduleRule rule,
  });
  Future<void> removeScheduleRule({
    required String clientId,
    required ScheduleRule rule,
  });
  Future<List<ScheduleTemplate>> getAllTemplates();
}
