import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { prepaid, deposit, refund, adjustment }

class ClientTransaction {
  final String id;
  final String clientId;
  final TransactionType type;
  final double amount;
  final double rateAtTime;
  final double? duration; // for session debits
  final String description;
  final DateTime timestamp;

  ClientTransaction({
    required this.id,
    required this.clientId,
    required this.type,
    required this.amount,
    required this.rateAtTime,
    this.duration,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'type': type.name,
      'amount': amount,
      'rateAtTime': rateAtTime,
      'duration': duration,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ClientTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return ClientTransaction(
      id: snapshot.id,
      clientId: data['clientId'] as String? ?? '',
      type: TransactionType.values.byName(data['type'] as String? ?? 'prepaid'),
      amount: (data['amount'] as num? ?? 0).toDouble(),
      rateAtTime: (data['rateAtTime'] as num? ?? 0).toDouble(),
      duration: (data['duration'] as num?)?.toDouble(),
      description: data['description'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
