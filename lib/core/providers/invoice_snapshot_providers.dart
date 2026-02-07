import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/services/firebase_service.dart';
import '../models/invoice_snapshot.dart';

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

  Future<void> deleteSnapshot({
    required String clientId,
    required String snapshotId,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    await firestore
        .collection('clients')
        .doc(clientId)
        .collection('invoice_snapshots')
        .doc(snapshotId)
        .delete();
  }
}
