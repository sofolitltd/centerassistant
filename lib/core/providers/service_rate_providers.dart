import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/service_rate.dart';
import '/services/firebase_service.dart';
import '../data/repositories/service_rate_repository_impl.dart';
import '../domain/repositories/service_rate_repository.dart';

final serviceRateRepositoryProvider = Provider<IServiceRateRepository>((ref) {
  return ServiceRateRepositoryImpl(ref.watch(firestoreProvider));
});

final allServiceRatesProvider = StreamProvider<List<ServiceRate>>((ref) {
  return ref.watch(serviceRateRepositoryProvider).getServiceRates();
});

final activeServiceRatesProvider = Provider<AsyncValue<List<ServiceRate>>>((
  ref,
) {
  return ref.watch(allServiceRatesProvider).whenData((rates) {
    return rates.where((r) => r.isActive).toList();
  });
});

final serviceRateServiceProvider = Provider(
  (ref) => ServiceRateActionService(ref),
);

class ServiceRateActionService {
  final Ref _ref;
  ServiceRateActionService(this._ref);

  Future<void> addRate({
    required String serviceType,
    required double hourlyRate,
    required DateTime effectiveDate,
  }) {
    return _ref
        .read(serviceRateRepositoryProvider)
        .addServiceRate(
          serviceType: serviceType,
          hourlyRate: hourlyRate,
          effectiveDate: effectiveDate,
        );
  }

  Future<void> updateRate(ServiceRate rate) {
    return _ref.read(serviceRateRepositoryProvider).updateServiceRate(rate);
  }

  Future<void> archiveRate(String id) {
    return _ref.read(serviceRateRepositoryProvider).archiveServiceRate(id);
  }

  Future<void> unarchiveRate(String id) {
    return _ref.read(serviceRateRepositoryProvider).unarchiveServiceRate(id);
  }

  Future<void> deleteRatePermanently(String id) {
    return _ref
        .read(serviceRateRepositoryProvider)
        .deleteServiceRatePermanently(id);
  }
}
