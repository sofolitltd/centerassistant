import '/core/models/client.dart';

abstract class IClientRepository {
  Stream<List<Client>> getClients();
  Stream<Client?> getClientById(String id);
  Future<void> addClient({
    required String name,
    required String nickName,
    required String mobileNo,
    required String email,
    required String address,
    required String gender,
    required DateTime dateOfBirth,
  });
  Future<void> updateClient(Client client);
  Future<void> deleteClient(String id);
}
