import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/models/client.dart';
import '/core/models/session.dart';
import '/core/models/transaction.dart';
import '/services/firebase_service.dart';

class SelectedBillingMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime date) {
    state = DateTime(date.year, date.month, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }
}

final selectedBillingMonthProvider =
    NotifierProvider<SelectedBillingMonthNotifier, DateTime>(
      SelectedBillingMonthNotifier.new,
    );

final isMonthBilledProvider = StreamProvider.family<bool, String>((
  ref,
  clientId,
) {
  final firestore = ref.watch(firestoreProvider);
  final monthDate = ref.watch(selectedBillingMonthProvider);
  final monthKey = DateFormat('yyyy-MM').format(monthDate);

  return firestore
      .collection('clients')
      .doc(clientId)
      .collection('billed_months')
      .doc(monthKey)
      .snapshots()
      .map((doc) => doc.exists);
});

final checkMonthBilledProvider =
    StreamProvider.family<bool, ({String clientId, String monthKey})>((
      ref,
      arg,
    ) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('clients')
          .doc(arg.clientId)
          .collection('billed_months')
          .doc(arg.monthKey)
          .snapshots()
          .map((doc) => doc.exists);
    });

final clientTransactionsProvider =
    StreamProvider.family<List<ClientTransaction>, String>((ref, clientId) {
      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('transactions')
          .where('clientId', isEqualTo: clientId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ClientTransaction.fromFirestore(doc))
                .toList(),
          );
    });

final allTransactionsProvider = StreamProvider<List<ClientTransaction>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('transactions')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => ClientTransaction.fromFirestore(doc))
            .toList(),
      );
});

final clientMonthlySessionsProvider =
    StreamProvider.family<List<Session>, String>((ref, clientId) {
      final firestore = ref.watch(firestoreProvider);
      final monthDate = ref.watch(selectedBillingMonthProvider);

      final firstDay = DateTime(monthDate.year, monthDate.month, 1);
      final lastDay = DateTime(
        monthDate.year,
        monthDate.month + 1,
        0,
        23,
        59,
        59,
      );

      return firestore
          .collection('schedule')
          .where('clientId', isEqualTo: clientId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList(),
          );
    });

final billingServiceProvider = Provider((ref) => BillingService(ref));

class BillingService {
  final Ref _ref;
  BillingService(this._ref);

  Future<void> addPayment({
    required Client client,
    required double amount,
    String description = 'Payment Received',
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.prepaid,
      amount: amount,
      rateAtTime: 0,
      description: description,
      timestamp: DateTime.now(),
    );

    final clientRef = firestore.collection('clients').doc(client.id);

    batch.set(transactionRef, transaction.toJson());
    batch.update(clientRef, {'walletBalance': FieldValue.increment(amount)});

    await batch.commit();
  }

  Future<void> addRefund({
    required Client client,
    required double amount,
    String description = 'Refund Processed',
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.refund,
      amount: -amount,
      rateAtTime: 0,
      description: description,
      timestamp: DateTime.now(),
    );

    final clientRef = firestore.collection('clients').doc(client.id);

    batch.set(transactionRef, transaction.toJson());
    batch.update(clientRef, {'walletBalance': FieldValue.increment(-amount)});

    await batch.commit();
  }

  Future<void> finalizeMonthlyBill({
    required Client client,
    required double totalBill,
    required DateTime monthDate,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();
    final monthKey = DateFormat('yyyy-MM').format(monthDate);
    final monthDisplay = DateFormat('MMMM yyyy').format(monthDate);

    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.prepaid,
      amount: -totalBill,
      rateAtTime: 0,
      description: 'Monthly Billing Settlement - $monthDisplay',
      timestamp: DateTime.now(),
    );
    batch.set(transactionRef, transaction.toJson());

    final clientRef = firestore.collection('clients').doc(client.id);
    batch.update(clientRef, {
      'walletBalance': FieldValue.increment(-totalBill),
    });

    final billedMonthRef = clientRef.collection('billed_months').doc(monthKey);
    batch.set(billedMonthRef, {
      'billedAt': Timestamp.now(),
      'totalAmount': totalBill,
      'month': monthKey,
      'transactionId': transactionRef.id,
    });

    await batch.commit();
  }

  Future<void> revertMonthlyBill({
    required String clientId,
    required String monthKey,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final clientRef = firestore.collection('clients').doc(clientId);
    final billedMonthRef = clientRef.collection('billed_months').doc(monthKey);

    final billedDoc = await billedMonthRef.get();
    if (billedDoc.exists) {
      final data = billedDoc.data()!;
      final totalAmount = (data['totalAmount'] as num).toDouble();
      final transactionId = data['transactionId'] as String;

      final batch = firestore.batch();

      // 1. Refund wallet balance
      batch.update(clientRef, {
        'walletBalance': FieldValue.increment(totalAmount),
      });

      // 2. Delete settlement transaction
      batch.delete(firestore.collection('transactions').doc(transactionId));

      // 3. Delete billed month record
      batch.delete(billedMonthRef);

      await batch.commit();
    }
  }

  Future<void> addSecurityDeposit({
    required Client client,
    required double amount,
    String description = 'Security Deposit',
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.deposit,
      amount: amount,
      rateAtTime: 0,
      description: description,
      timestamp: DateTime.now(),
    );

    final clientRef = firestore.collection('clients').doc(client.id);

    batch.set(transactionRef, transaction.toJson());
    batch.update(clientRef, {'securityDeposit': FieldValue.increment(amount)});

    await batch.commit();
  }

  Future<void> applyAdjustment({
    required Client client,
    required double amount,
    String description = 'Security Deposit Adjustment',
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.adjustment,
      amount: amount,
      rateAtTime: 0,
      description: description,
      timestamp: DateTime.now(),
    );

    final clientRef = firestore.collection('clients').doc(client.id);

    batch.set(transactionRef, transaction.toJson());
    batch.update(clientRef, {
      'securityDeposit': FieldValue.increment(-amount),
      'walletBalance': FieldValue.increment(amount),
    });

    await batch.commit();
  }

  Future<void> updateTransaction({
    required ClientTransaction oldTx,
    required double newAmount,
    required String newDescription,
    required TransactionType newType,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    // 1. Revert old transaction effect
    final clientRef = firestore.collection('clients').doc(oldTx.clientId);
    if (oldTx.type == TransactionType.deposit) {
      batch.update(clientRef, {
        'securityDeposit': FieldValue.increment(-oldTx.amount),
      });
    } else if (oldTx.type == TransactionType.adjustment) {
      batch.update(clientRef, {
        'securityDeposit': FieldValue.increment(oldTx.amount),
        'walletBalance': FieldValue.increment(-oldTx.amount),
      });
    } else {
      batch.update(clientRef, {
        'walletBalance': FieldValue.increment(-oldTx.amount),
      });
    }

    // 2. Apply new transaction effect
    if (newType == TransactionType.deposit) {
      batch.update(clientRef, {
        'securityDeposit': FieldValue.increment(newAmount),
      });
    } else if (newType == TransactionType.adjustment) {
      batch.update(clientRef, {
        'securityDeposit': FieldValue.increment(-newAmount),
        'walletBalance': FieldValue.increment(newAmount),
      });
    } else {
      batch.update(clientRef, {
        'walletBalance': FieldValue.increment(newAmount),
      });
    }

    // 3. Update the transaction document
    batch.update(firestore.collection('transactions').doc(oldTx.id), {
      'amount': newAmount,
      'description': newDescription,
      'type': newType.name,
    });

    await batch.commit();
  }

  Future<void> deleteTransaction(ClientTransaction tx) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final clientRef = firestore.collection('clients').doc(tx.clientId);
    if (tx.type == TransactionType.deposit) {
      batch.update(clientRef, {
        'securityDeposit': FieldValue.increment(-tx.amount),
      });
    } else if (tx.type == TransactionType.adjustment) {
      batch.update(clientRef, {
        'securityDeposit': FieldValue.increment(tx.amount),
        'walletBalance': FieldValue.increment(-tx.amount),
      });
    } else {
      batch.update(clientRef, {
        'walletBalance': FieldValue.increment(-tx.amount),
      });
    }

    batch.delete(firestore.collection('transactions').doc(tx.id));

    await batch.commit();
  }
}
