import 'package:cloud_firestore/cloud_firestore.dart';

class ClientDiscount {
  final String id;
  final String clientId;
  final String serviceType;
  final double discountPerHour;
  final DateTime effectiveDate;
  final DateTime? endDate;
  final bool isActive;

  ClientDiscount({
    required this.id,
    required this.clientId,
    required this.serviceType,
    required this.discountPerHour,
    required this.effectiveDate,
    this.endDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'serviceType': serviceType,
      'discountPerHour': discountPerHour,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }

  factory ClientDiscount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientDiscount(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      discountPerHour: (data['discountPerHour'] as num?)?.toDouble() ?? 0.0,
      effectiveDate: (data['effectiveDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  ClientDiscount copyWith({
    String? serviceType,
    double? discountPerHour,
    DateTime? effectiveDate,
    DateTime? Function()? endDate,
    bool? isActive,
  }) {
    return ClientDiscount(
      id: id,
      clientId: clientId,
      serviceType: serviceType ?? this.serviceType,
      discountPerHour: discountPerHour ?? this.discountPerHour,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      endDate: endDate != null ? endDate() : this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
