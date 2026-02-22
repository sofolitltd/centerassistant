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
    required String clientId,
    required String name,
    required String nickName,
    required String mobileNo,
    required String email,
    required String address,
    required String gender,
    required DateTime dateOfBirth,
    String fatherName = '',
    String fatherContact = '',
    String motherName = '',
    String motherContact = '',
    DateTime? enrollmentDate,
    DateTime? discontinueDate,
  }) async {
    final counterRef = _firestore.collection('counters').doc('clients');

    return _firestore.runTransaction((transaction) async {
      // 1. Generate random document ID for Firestore
      final newClientRef = _firestore.collection('clients').doc();
      final docId = newClientRef.id;

      final newClient = Client(
        id: docId,
        clientId: clientId,
        name: name,
        nickName: nickName,
        mobileNo: mobileNo,
        email: email,
        address: address,
        gender: gender,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
        fatherName: fatherName,
        fatherContact: fatherContact,
        motherName: motherName,
        motherContact: motherContact,
        enrollmentDate: enrollmentDate ?? DateTime.now(),
        discontinueDate: discontinueDate,
      );

      transaction.set(newClientRef, newClient.toJson());

      // 2. Update the counter to match the numeric part of the provided ID
      // This ensures the next auto-generated ID is correct.
      try {
        final numericId = int.parse(clientId);
        transaction.set(counterRef, {'count': numericId}, SetOptions(merge: true));
      } catch (_) {
        // If clientId is not numeric, we don't update the counter
      }
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
  }
}
