import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRate {
  final String id;
  final String serviceType; // e.g., "ABA", "SLT", "OT"
  final double hourlyRate;
  final DateTime effectiveDate;
  final DateTime? endDate;

  ServiceRate({
    required this.id,
    required this.serviceType,
    required this.hourlyRate,
    required this.effectiveDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'hourlyRate': hourlyRate,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  factory ServiceRate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRate(
      id: doc.id,
      serviceType: data['serviceType'] ?? '',
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: (data['effectiveDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  ServiceRate copyWith({
    String? id,
    String? serviceType,
    double? hourlyRate,
    DateTime? effectiveDate,
    DateTime? endDate,
  }) {
    return ServiceRate(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
