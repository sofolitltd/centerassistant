import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType { regular, cover, makeup, extra, cancelled, completed }

class Session {
  final String id;
  final String clientId;
  final String employeeId;
  final String timeSlotId;
  final Timestamp date;
  final SessionType sessionType;
  final String? notes;
  final String? originalEmployeeId;
  final Timestamp createdAt;

  Session({
    required this.id,
    required this.clientId,
    required this.employeeId,
    required this.timeSlotId,
    required this.date,
    required this.sessionType,
    this.notes,
    this.originalEmployeeId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'employeeId': employeeId,
      'timeSlotId': timeSlotId,
      'date': date,
      'sessionType': sessionType.name,
      'notes': notes,
      'originalEmployeeId': originalEmployeeId,
      'createdAt': createdAt,
    };
  }

  factory Session.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Session(
      id: snapshot.id,
      clientId: data['clientId'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      timeSlotId: data['timeSlotId'] as String? ?? '',
      date: (data['date'] as Timestamp?) ?? Timestamp.now(),
      sessionType: SessionType.values.byName(
        data['sessionType'] as String? ?? 'regular',
      ),
      notes: data['notes'] as String?,
      originalEmployeeId: data['originalEmployeeId'] as String?,
      createdAt: data['createdAt'] as Timestamp,
    );
  }
}
