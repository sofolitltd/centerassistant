import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRate {
  final String id;
  final String serviceType; // e.g., "ABA", "SLT", "OT"
  final double hourlyRate;
  final DateTime effectiveDate;
  final bool isActive;

  ServiceRate({
    required this.id,
    required this.serviceType,
    required this.hourlyRate,
    required this.effectiveDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'hourlyRate': hourlyRate,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
      'isActive': isActive,
    };
  }

  factory ServiceRate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRate(
      id: doc.id,
      serviceType: data['serviceType'] ?? '',
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: (data['effectiveDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}
