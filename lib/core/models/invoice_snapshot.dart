import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceType { pre, post }

class InvoiceSnapshot {
  final String id;
  final String clientId;
  final String monthKey; // yyyy-MM
  final InvoiceType type;
  final DateTime generatedAt;
  final double totalAmount;
  final double totalHours;
  final double walletBalanceAtTime;
  final List<Map<String, dynamic>> sessionsJson; // Snapshotted session data

  InvoiceSnapshot({
    required this.id,
    required this.clientId,
    required this.monthKey,
    required this.type,
    required this.generatedAt,
    required this.totalAmount,
    required this.totalHours,
    required this.walletBalanceAtTime,
    required this.sessionsJson,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'monthKey': monthKey,
      'type': type.name,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'totalAmount': totalAmount,
      'totalHours': totalHours,
      'walletBalanceAtTime': walletBalanceAtTime,
      'sessionsJson': sessionsJson,
    };
  }

  factory InvoiceSnapshot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceSnapshot(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      monthKey: data['monthKey'] ?? '',
      type: InvoiceType.values.byName(data['type'] ?? 'pre'),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] as num? ?? 0.0).toDouble(),
      totalHours: (data['totalHours'] as num? ?? 0.0).toDouble(),
      walletBalanceAtTime: (data['walletBalanceAtTime'] as num? ?? 0.0)
          .toDouble(),
      sessionsJson: List<Map<String, dynamic>>.from(data['sessionsJson'] ?? []),
    );
  }
}
