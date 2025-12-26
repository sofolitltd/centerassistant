import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String id;
  final String startTime;
  final String endTime;
  final String label;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.label = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
    };
  }

  factory TimeSlot.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return TimeSlot(
      id: snapshot.id,
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      label: data['label'] as String? ?? '',
    );
  }
}
