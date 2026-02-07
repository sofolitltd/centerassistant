import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/services/firebase_service.dart';
import '../models/invoice_snapshot.dart';
import 'billing_providers.dart';

final invoiceSnapshotsProvider =
    StreamProvider.family<
      List<InvoiceSnapshot>,
      ({String clientId, InvoiceType type})
    >((ref, arg) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(arg.clientId)
          .collection('invoice_snapshots')
          .where('type', isEqualTo: arg.type.name)
          .orderBy('generatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => InvoiceSnapshot.fromFirestore(doc))
                .toList(),
          );
    });

final invoiceSnapshotsByMonthProvider =
    StreamProvider.family<
      List<InvoiceSnapshot>,
      ({String clientId, String monthKey, InvoiceType type})
    >((ref, arg) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(arg.clientId)
          .collection('invoice_snapshots')
          .where('monthKey', isEqualTo: arg.monthKey)
          .where('type', isEqualTo: arg.type.name)
          .orderBy('generatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => InvoiceSnapshot.fromFirestore(doc))
                .toList(),
          );
    });

final allInvoiceSnapshotsByMonthProvider =
    StreamProvider.family<
      List<InvoiceSnapshot>,
      ({String monthKey, InvoiceType type})
    >((ref, arg) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collectionGroup('invoice_snapshots')
          .where('monthKey', isEqualTo: arg.monthKey)
          .where('type', isEqualTo: arg.type.name)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => InvoiceSnapshot.fromFirestore(doc))
                .toList(),
          );
    });

final allInvoiceSnapshotsByRangeProvider =
    StreamProvider.family<List<InvoiceSnapshot>, int>((ref, months) {
      final firestore = ref.watch(firestoreProvider);
      final monthKeys = List.generate(months, (i) {
        final date = DateTime.now().subtract(Duration(days: 30 * i));
        return "${date.year}-${date.month.toString().padLeft(2, '0')}";
      });

      return firestore
          .collectionGroup('invoice_snapshots')
          .where('monthKey', whereIn: monthKeys)
          .where('type', isEqualTo: InvoiceType.post.name)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => InvoiceSnapshot.fromFirestore(doc))
                .toList(),
          );
    });

final hasSnapshotProvider =
    StreamProvider.family<
      bool,
      ({String clientId, String monthKey, InvoiceType type})
    >((ref, arg) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(arg.clientId)
          .collection('invoice_snapshots')
          .where('monthKey', isEqualTo: arg.monthKey)
          .where('type', isEqualTo: arg.type.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty);
    });

final hasPreSnapshotProvider =
    StreamProvider.family<bool, ({String clientId, String monthKey})>((
      ref,
      arg,
    ) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(arg.clientId)
          .collection('invoice_snapshots')
          .where('monthKey', isEqualTo: arg.monthKey)
          .where('type', isEqualTo: InvoiceType.pre.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty);
    });

final hasPostSnapshotProvider =
    StreamProvider.family<bool, ({String clientId, String monthKey})>((
      ref,
      arg,
    ) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(arg.clientId)
          .collection('invoice_snapshots')
          .where('monthKey', isEqualTo: arg.monthKey)
          .where('type', isEqualTo: InvoiceType.post.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty);
    });

final invoiceSnapshotServiceProvider = Provider(
  (ref) => InvoiceSnapshotActionService(ref),
);

class InvoiceSnapshotActionService {
  final Ref _ref;
  InvoiceSnapshotActionService(this._ref);

  Future<void> createSnapshot({
    required String clientId,
    required String monthKey,
    required InvoiceType type,
    required double totalAmount,
    required double totalHours,
    required double walletBalance,
    required List<Map<String, dynamic>> sessionsJson,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final docRef = firestore
        .collection('clients')
        .doc(clientId)
        .collection('invoice_snapshots')
        .doc();

    final snapshot = InvoiceSnapshot(
      id: docRef.id,
      clientId: clientId,
      monthKey: monthKey,
      type: type,
      generatedAt: DateTime.now(),
      totalAmount: totalAmount,
      totalHours: totalHours,
      walletBalanceAtTime: walletBalance,
      sessionsJson: sessionsJson,
    );

    await docRef.set(snapshot.toJson());
  }

  Future<void> deleteSnapshot(InvoiceSnapshot snapshot) async {
    final firestore = _ref.read(firestoreProvider);

    // If it's a POST invoice, we must revert the wallet balance effect first
    if (snapshot.type == InvoiceType.post) {
      await _ref.read(billingServiceProvider).revertMonthlyBill(
            clientId: snapshot.clientId,
            monthKey: snapshot.monthKey,
          );
    }

    // Now delete the snapshot itself
    await firestore
        .collection('clients')
        .doc(snapshot.clientId)
        .collection('invoice_snapshots')
        .doc(snapshot.id)
        .delete();
  }
}
