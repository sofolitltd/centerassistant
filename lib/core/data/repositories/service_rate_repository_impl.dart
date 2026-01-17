import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/service_rate.dart';
import '../../domain/repositories/service_rate_repository.dart';

class ServiceRateRepositoryImpl implements IServiceRateRepository {
  final FirebaseFirestore _firestore;

  ServiceRateRepositoryImpl(this._firestore);

  @override
  Stream<List<ServiceRate>> getServiceRates() {
    return _firestore.collection('service_rates').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceRate.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> addServiceRate({
    required String serviceType,
    required double hourlyRate,
    required DateTime effectiveDate,
  }) async {
    final docRef = _firestore.collection('service_rates').doc();
    final newRate = ServiceRate(
      id: docRef.id,
      serviceType: serviceType,
      hourlyRate: hourlyRate,
      effectiveDate: effectiveDate,
      isActive: true,
    );
    await docRef.set(newRate.toJson());
  }

  @override
  Future<void> updateServiceRate(ServiceRate rate) async {
    await _firestore
        .collection('service_rates')
        .doc(rate.id)
        .update(rate.toJson());
  }

  @override
  Future<void> archiveServiceRate(String id) async {
    await _firestore.collection('service_rates').doc(id).update({
      'isActive': false,
    });
  }

  @override
  Future<void> unarchiveServiceRate(String id) async {
    await _firestore.collection('service_rates').doc(id).update({
      'isActive': true,
    });
  }

  @override
  Future<void> deleteServiceRatePermanently(String id) async {
    await _firestore.collection('service_rates').doc(id).delete();
  }
}
