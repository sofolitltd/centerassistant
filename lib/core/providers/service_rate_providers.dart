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
    final now = DateTime.now();
    return rates.where((r) {
      final isEffective = !r.effectiveDate.isAfter(now);
      final isNotEnded = r.endDate == null || r.endDate!.isAfter(now);
      return isEffective && isNotEnded;
    }).toList();
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
    DateTime? endDate,
  }) {
    return _ref
        .read(serviceRateRepositoryProvider)
        .addServiceRate(
          serviceType: serviceType,
          hourlyRate: hourlyRate,
          effectiveDate: effectiveDate,
          endDate: endDate,
        );
  }

  Future<void> updateRate(ServiceRate rate) {
    return _ref.read(serviceRateRepositoryProvider).updateServiceRate(rate);
  }

  Future<void> deleteRate(String id) {
    return _ref.read(serviceRateRepositoryProvider).deleteServiceRate(id);
  }
}
