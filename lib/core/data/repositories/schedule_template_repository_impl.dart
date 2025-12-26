import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/schedule_template.dart';
import '../../domain/repositories/schedule_template_repository.dart';

class ScheduleTemplateRepositoryImpl implements IScheduleTemplateRepository {
  final FirebaseFirestore _firestore;

  ScheduleTemplateRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _templatesCollection =>
      _firestore.collection('schedule_templates');

  @override
  Stream<ScheduleTemplate?> getScheduleTemplateByClientId(String clientId) {
    return _templatesCollection
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ScheduleTemplate.fromFirestore(snapshot.docs.first);
        });
  }

  @override
  Future<void> setScheduleRule({
    required String clientId,
    required ScheduleRule rule,
  }) async {
    final query = await _templatesCollection
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      final newTemplate = ScheduleTemplate(
        id: _templatesCollection.doc().id,
        clientId: clientId,
        rules: [rule],
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await _templatesCollection.doc(newTemplate.id).set(newTemplate.toJson());
    } else {
      final docRef = query.docs.first.reference;
      await docRef.update({
        'rules': FieldValue.arrayUnion([rule.toJson()]),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  @override
  Future<void> removeScheduleRule({
    required String clientId,
    required ScheduleRule rule,
  }) async {
    final query = await _templatesCollection
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      await docRef.update({
        'rules': FieldValue.arrayRemove([rule.toJson()]),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  @override
  Future<List<ScheduleTemplate>> getAllTemplates() async {
    final snapshot = await _templatesCollection.get();
    return snapshot.docs
        .map((doc) => ScheduleTemplate.fromFirestore(doc))
        .toList();
  }
}
