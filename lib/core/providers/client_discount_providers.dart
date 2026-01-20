import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client_discount.dart';
import '/services/firebase_service.dart';

final clientDiscountsProvider =
    StreamProvider.family<List<ClientDiscount>, String>((ref, clientId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(clientId)
          .collection('discounts')
          .orderBy('effectiveDate', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ClientDiscount.fromFirestore(doc))
                .toList(),
          );
    });

final activeClientDiscountsProvider =
    Provider.family<AsyncValue<List<ClientDiscount>>, String>((ref, clientId) {
      return ref.watch(clientDiscountsProvider(clientId)).whenData((discounts) {
        return discounts.where((d) => d.isActive).toList();
      });
    });

final clientDiscountServiceProvider = Provider(
  (ref) => ClientDiscountActionService(ref),
);

class ClientDiscountActionService {
  final Ref _ref;
  ClientDiscountActionService(this._ref);

  Future<void> addDiscount({
    required String clientId,
    required String serviceType,
    required double discountPerHour,
    required DateTime effectiveDate,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final docRef = firestore
        .collection('clients')
        .doc(clientId)
        .collection('discounts')
        .doc();

    final discount = ClientDiscount(
      id: docRef.id,
      clientId: clientId,
      serviceType: serviceType,
      discountPerHour: discountPerHour,
      effectiveDate: effectiveDate,
      isActive: true,
    );

    await docRef.set(discount.toJson());
  }

  Future<void> updateDiscount(ClientDiscount discount) async {
    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('clients')
        .doc(discount.clientId)
        .collection('discounts')
        .doc(discount.id)
        .update(discount.toJson());
  }

  Future<void> toggleDiscountStatus(ClientDiscount discount) async {
    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('clients')
        .doc(discount.clientId)
        .collection('discounts')
        .doc(discount.id)
        .update({'isActive': !discount.isActive});
  }

  Future<void> deleteDiscount(ClientDiscount discount) async {
    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('clients')
        .doc(discount.clientId)
        .collection('discounts')
        .doc(discount.id)
        .delete();
  }
}
