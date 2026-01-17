import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly, none }

enum RecurrenceEndType { onDate, afterOccurrences }

class ScheduleRule {
  final List<String> daysOfWeek; // For weekly: ['Monday', 'Wednesday', etc.]
  final int? dayOfMonth; // For monthly: 1-31
  final RecurrenceFrequency frequency;
  final int interval; // Repeat every [n] unit
  final String timeSlotId;
  final String employeeId;
  final String serviceType;
  final String startTime;
  final String endTime;
  final RecurrenceEndType endType;
  final DateTime? startDate; // Effective start date
  final DateTime? untilDate;
  final int? occurrences;

  ScheduleRule({
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.frequency = RecurrenceFrequency.weekly,
    this.interval = 1,
    required this.timeSlotId,
    required this.employeeId,
    this.serviceType = 'ABA',
    required this.startTime,
    required this.endTime,
    this.endType = RecurrenceEndType.onDate,
    this.startDate,
    this.untilDate,
    this.occurrences,
  });

  Map<String, dynamic> toJson() {
    return {
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'frequency': frequency.name,
      'interval': interval,
      'timeSlotId': timeSlotId,
      'employeeId': employeeId,
      'serviceType': serviceType,
      'startTime': startTime,
      'endTime': endTime,
      'endType': endType.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'untilDate': untilDate != null ? Timestamp.fromDate(untilDate!) : null,
      'occurrences': occurrences,
    };
  }

  factory ScheduleRule.fromJson(Map<String, dynamic> json) {
    return ScheduleRule(
      daysOfWeek: List<String>.from(json['daysOfWeek'] ?? []),
      dayOfMonth: json['dayOfMonth'] as int?,
      frequency: RecurrenceFrequency.values.byName(
        json['frequency'] as String? ?? 'weekly',
      ),
      interval: json['interval'] as int? ?? 1,
      timeSlotId: (json['timeSlotId'] as String?) ?? '',
      employeeId: (json['employeeId'] as String?) ?? '',
      serviceType: (json['serviceType'] as String?) ?? 'ABA',
      startTime: (json['startTime'] as String?) ?? '',
      endTime: (json['endTime'] as String?) ?? '',
      endType: RecurrenceEndType.values.byName(
        json['endType'] as String? ?? 'onDate',
      ),
      startDate: (json['startDate'] as Timestamp?)?.toDate(),
      untilDate: (json['untilDate'] as Timestamp?)?.toDate(),
      occurrences: json['occurrences'] as int?,
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
