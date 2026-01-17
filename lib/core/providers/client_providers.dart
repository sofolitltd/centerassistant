import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/data/repositories/client_repository_impl.dart';
import '/core/domain/repositories/client_repository.dart';
import '/core/models/client.dart';
import '/services/firebase_service.dart';

final clientRepositoryProvider = Provider<IClientRepository>((ref) {
  return ClientRepositoryImpl(ref.watch(firestoreProvider));
});

final clientsProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).getClients();
});

final clientByIdProvider = StreamProvider.family<Client?, String>((ref, id) {
  return ref.watch(clientRepositoryProvider).getClientById(id);
});

final clientServiceProvider = Provider((ref) => ClientActionService(ref));

class ClientActionService {
  final Ref _ref;
  ClientActionService(this._ref);

  Future<void> addClient({
    required String name,
    required String nickName,
    required String mobileNo,
    required String email,
    required String address,
    required String gender,
    required DateTime dateOfBirth,
  }) {
    return _ref
        .read(clientRepositoryProvider)
        .addClient(
          name: name,
          nickName: nickName,
          mobileNo: mobileNo,
          email: email,
          address: address,
          gender: gender,
          dateOfBirth: dateOfBirth,
        );
  }

  Future<void> updateClient(Client client) {
    return _ref.read(clientRepositoryProvider).updateClient(client);
  }

  Future<void> deleteClient(String id) {
    return _ref.read(clientRepositoryProvider).deleteClient(id);
  }
}
