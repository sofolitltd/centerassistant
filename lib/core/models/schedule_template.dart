import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleRule {
  final String dayOfWeek;
  final String timeSlotId;
  final String employeeId;
  final String serviceType;

  ScheduleRule({
    required this.dayOfWeek,
    required this.timeSlotId,
    required this.employeeId,
    this.serviceType = 'ABA',
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'timeSlotId': timeSlotId,
      'employeeId': employeeId,
      'serviceType': serviceType,
    };
  }

  factory ScheduleRule.fromJson(Map<String, dynamic> json) {
    return ScheduleRule(
      dayOfWeek: (json['dayOfWeek'] as String?) ?? '',
      timeSlotId: (json['timeSlotId'] as String?) ?? '',
      employeeId: (json['employeeId'] as String?) ?? '',
      serviceType: (json['serviceType'] as String?) ?? 'ABA',
    );
  }
}

class ScheduleTemplate {
  final String id;
  final String clientId;
  final List<ScheduleRule> rules;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ScheduleTemplate({
    required this.id,
    required this.clientId,
    required this.rules,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'rules': rules.map((rule) => rule.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ScheduleTemplate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return ScheduleTemplate(
      id: snapshot.id,
      clientId: (data['clientId'] as String?) ?? '',
      rules:
          (data['rules'] as List<dynamic>?)
              ?.map(
                (rule) => ScheduleRule.fromJson(rule as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
    );
  }
}
