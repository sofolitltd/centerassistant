import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveEntityType { employee, client }

class Leave {
  final String id;
  final String entityId; // employeeId or clientId
  final LeaveEntityType entityType;
  final DateTime date;
  final String? reason;

  Leave({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.date,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType.name,
      'date': Timestamp.fromDate(date),
      'reason': reason,
    };
  }

  factory Leave.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Leave(
      id: snapshot.id,
      entityId: data['entityId'] as String? ?? '',
      entityType: LeaveEntityType.values.byName(
        data['entityType'] as String? ?? 'employee',
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'] as String?,
    );
  }
}
