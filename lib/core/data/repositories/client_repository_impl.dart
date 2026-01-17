import 'package:cloud_firestore/cloud_firestore.dart';

import '/core/models/client.dart';
import '../../domain/repositories/client_repository.dart';

class ClientRepositoryImpl implements IClientRepository {
  final FirebaseFirestore _firestore;

  ClientRepositoryImpl(this._firestore);

  @override
  Stream<List<Client>> getClients() {
    return _firestore
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Client.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
        });
  }

  @override
  Stream<Client?> getClientById(String id) {
    return _firestore.collection('clients').doc(id).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Client.fromFirestore(snapshot);
      }
      return null;
    });
  }

  @override
  Future<void> addClient({
    required String name,
    required String nickName,
    required String mobileNo,
    required String email,
    required String address,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    final counterRef = _firestore.collection('counters').doc('clients');

    return _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);

      int newIdNumber;
      if (!counterSnapshot.exists) {
        newIdNumber = 1;
      } else {
        final data = counterSnapshot.data();
        newIdNumber = (data?['count'] as int? ?? 0) + 1;
      }

      // 1. Generate random document ID
      final newClientRef = _firestore.collection('clients').doc();
      final docId = newClientRef.id;

      // 2. Generate sequential ID field (e.g. 0001)
      final sequentialId = newIdNumber.toString().padLeft(4, '0');

      final newClient = Client(
        id: docId,
        clientId: sequentialId,
        name: name,
        nickName: nickName,
        mobileNo: mobileNo,
        email: email,
        address: address,
        gender: gender,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
      );

      transaction.set(newClientRef, newClient.toJson());
      transaction.set(counterRef, {'count': newIdNumber});
    });
  }

  @override
  Future<void> updateClient(Client client) async {
    await _firestore
        .collection('clients')
        .doc(client.id)
        .update(client.toJson());
  }

  @override
  Future<void> deleteClient(String id) async {
    final clientRef = _firestore.collection('clients').doc(id);
    await clientRef.delete();
    // Counter decrement is usually not recommended for sequential IDs 
    // to avoid ID reuse and complexity, so we only delete the document.
  }
}
