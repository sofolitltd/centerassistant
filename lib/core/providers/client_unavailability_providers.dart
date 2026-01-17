import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/services/firebase_service.dart';
import '../models/client_unavailability.dart';

final clientUnavailabilityProvider =
    StreamProvider.family<List<ClientUnavailability>, String>((ref, clientId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('client_unavailability')
          .where('clientId', isEqualTo: clientId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => ClientUnavailability.fromFirestore(doc))
                .toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    });

final clientUnavailabilityServiceProvider = Provider(
  (ref) => ClientUnavailabilityService(ref),
);

class ClientUnavailabilityService {
  final Ref _ref;
  ClientUnavailabilityService(this._ref);

  Future<void> addUnavailability({
    required String clientId,
    required DateTime date,
    String? note,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final id = firestore.collection('client_unavailability').doc().id;
    final unavailability = ClientUnavailability(
      id: id,
      clientId: clientId,
      date: DateTime(date.year, date.month, date.day),
      note: note,
      createdAt: DateTime.now(),
    );
    await firestore
        .collection('client_unavailability')
        .doc(id)
        .set(unavailability.toJson());
  }

  Future<void> addUnavailabilityRange({
    required String clientId,
    required DateTime start,
    required DateTime end,
    String? note,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();
    
    DateTime current = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    while (current.isBefore(normalizedEnd) || current.isAtSameMomentAs(normalizedEnd)) {
      final docRef = firestore.collection('client_unavailability').doc();
      final unavailability = ClientUnavailability(
        id: docRef.id,
        clientId: clientId,
        date: current,
        note: note,
        createdAt: DateTime.now(),
      );
      batch.set(docRef, unavailability.toJson());
      current = current.add(const Duration(days: 1));
    }

    await batch.commit();
  }

  Future<void> removeUnavailability(String id) async {
    final firestore = _ref.read(firestoreProvider);
    await firestore.collection('client_unavailability').doc(id).delete();
  }
}
