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

  String _getDeterministicId(
    DateTime date,
    String clientId,
    String timeSlotId,
  ) {
    return '${date.year}-${date.month}-${date.day}_${clientId}_$timeSlotId';
  }

  Future<void> addPayment({
    required Client client,
    required double amount,
    String description = 'Prepaid Payment',
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.credit,
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
      type: TransactionType.adjustment,
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

  Future<void> adjustMonthlyBill({
    required Client client,
    required double totalBill,
    required DateTime monthDate,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final monthName = DateFormat('MMMM yyyy').format(monthDate);
    final transactionRef = firestore.collection('transactions').doc();
    final transaction = ClientTransaction(
      id: transactionRef.id,
      clientId: client.id,
      type: TransactionType.debit,
      amount: -totalBill,
      rateAtTime: 0,
      description: 'Monthly Bill Adjustment: $monthName',
      timestamp: DateTime.now(),
    );

    final clientRef = firestore.collection('clients').doc(client.id);

    batch.set(transactionRef, transaction.toJson());
    batch.update(clientRef, {
      'walletBalance': FieldValue.increment(-totalBill),
    });

    await batch.commit();
  }

  Future<void> updateTransaction({
    required ClientTransaction oldTx,
    required double newAmount,
    required String newDescription,
  }) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final diff = newAmount - oldTx.amount;
    final balanceField = oldTx.type == TransactionType.adjustment
        ? 'securityDeposit'
        : 'walletBalance';

    batch.update(firestore.collection('transactions').doc(oldTx.id), {
      'amount': newAmount,
      'description': newDescription,
    });

    batch.update(firestore.collection('clients').doc(oldTx.clientId), {
      balanceField: FieldValue.increment(diff),
    });

    await batch.commit();
  }

  Future<void> deleteTransaction(ClientTransaction tx) async {
    final firestore = _ref.read(firestoreProvider);
    final batch = firestore.batch();

    final amountToRevert = -tx.amount;
    final balanceField = tx.type == TransactionType.adjustment
        ? 'securityDeposit'
        : 'walletBalance';

    batch.delete(firestore.collection('transactions').doc(tx.id));
    batch.update(firestore.collection('clients').doc(tx.clientId), {
      balanceField: FieldValue.increment(amountToRevert),
    });

    await batch.commit();
  }
}
