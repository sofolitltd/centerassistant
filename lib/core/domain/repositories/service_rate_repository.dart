import '/core/models/service_rate.dart';

abstract class IServiceRateRepository {
  Stream<List<ServiceRate>> getServiceRates();
  Future<void> addServiceRate({
    required String serviceType,
    required double hourlyRate,
    required DateTime effectiveDate,
  });
  Future<void> updateServiceRate(ServiceRate rate);
  Future<void> archiveServiceRate(String id);
  Future<void> unarchiveServiceRate(String id);
  Future<void> deleteServiceRatePermanently(String id);
}
