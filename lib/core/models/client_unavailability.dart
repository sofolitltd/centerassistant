import 'package:cloud_firestore/cloud_firestore.dart';

class ClientUnavailability {
  final String id;
  final String clientId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  ClientUnavailability({
    required this.id,
    required this.clientId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ClientUnavailability.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return ClientUnavailability(
      id: snapshot.id,
      clientId: data['clientId'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
