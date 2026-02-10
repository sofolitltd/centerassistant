import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String id;
  final String startTime; // 24h format "HH:mm"
  final String endTime; // 24h format "HH:mm"
  final String label;
  final bool isActive;
  final DateTime effectiveDate;
  final DateTime? effectiveEndDate;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.label = '',
    this.isActive = true,
    required this.effectiveDate,
    this.effectiveEndDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
      'isActive': isActive,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
      'effectiveEndDate': effectiveEndDate != null
          ? Timestamp.fromDate(effectiveEndDate!)
          : null,
    };
  }

  factory TimeSlot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return TimeSlot(
      id: snapshot.id,
      startTime: data['startTime'] as String? ?? '00:00',
      endTime: data['endTime'] as String? ?? '00:00',
      label: data['label'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      effectiveDate:
          (data['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      effectiveEndDate: (data['effectiveEndDate'] as Timestamp?)?.toDate(),
    );
  }
}
