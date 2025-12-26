import '/core/models/session.dart';

abstract class ISessionRepository {
  Future<void> createSessionException(Session session);
  Future<void> deleteSessionException(String sessionId);
  Future<List<Session>> getSessionsByDate(DateTime date);
}
