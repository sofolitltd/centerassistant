import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/domain/repositories/session_repository.dart';
import '/core/models/session.dart';

class SessionRepositoryImpl implements ISessionRepository {
  final FirebaseFirestore _firestore;

  SessionRepositoryImpl(this._firestore);

  @override
  Future<void> createSessionException(Session session) async {
    await _firestore
        .collection('schedule')
        .doc(session.id)
        .set(session.toJson());
  }

  @override
  Future<void> deleteSessionException(String sessionId) async {
    await _firestore.collection('schedule').doc(sessionId).delete();
  }

  @override
  Future<List<Session>> getSessionsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final snapshot = await _firestore
        .collection('schedule')
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    return snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList();
  }
}
