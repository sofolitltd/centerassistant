import '/core/models/service_rate.dart';

abstract class IServiceRateRepository {
  Stream<List<ServiceRate>> getServiceRates();
  Future<void> addServiceRate({
    required String serviceType,
    required double hourlyRate,
    required DateTime effectiveDate,
    DateTime? endDate,
  });
  Future<void> updateServiceRate(ServiceRate rate);
  Future<void> deleteServiceRate(String id);
}
