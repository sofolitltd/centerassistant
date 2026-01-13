import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType {
  regular,
  cover,
  makeup,
  extra,
  cancelled,
  cancelledCenter,
  cancelledClient,
  completed
}

class Session {
  final String id;
  final String clientId;
  final String employeeId;
  final String timeSlotId;
  final Timestamp date;
  final SessionType sessionType;
  final String serviceType; // e.g., 'ABA', 'SLT', 'OT'
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
    this.serviceType = 'ABA',
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
      'serviceType': serviceType,
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
      serviceType: data['serviceType'] as String? ?? 'ABA',
      notes: data['notes'] as String?,
      originalEmployeeId: data['originalEmployeeId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Session copyWith({
    String? id,
    String? clientId,
    String? employeeId,
    String? timeSlotId,
    Timestamp? date,
    SessionType? sessionType,
    String? serviceType,
    String? notes,
    String? originalEmployeeId,
    Timestamp? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      employeeId: employeeId ?? this.employeeId,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      date: date ?? this.date,
      sessionType: sessionType ?? this.sessionType,
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      originalEmployeeId: originalEmployeeId ?? this.originalEmployeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
