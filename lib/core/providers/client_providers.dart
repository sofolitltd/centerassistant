import 'package:flutter/foundation.dart';
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

final nextClientIdProvider = FutureProvider.autoDispose<String>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final collection = firestore.collection('clients');

  String? lastId;

  // 1. Try to get the latest client by createdAt (most likely to have the current ID pattern)
  try {
    final snapshot = await collection
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      lastId = snapshot.docs.first.data()['clientId'] as String?;
    }
  } catch (e) {
    debugPrint('nextClientIdProvider: orderBy createdAt failed: $e');
  }

  // 2. Fallback: Try by clientId descending (lexicographical highest)
  if (lastId == null) {
    try {
      final snapshot = await collection
          .orderBy('clientId', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        lastId = snapshot.docs.first.data()['clientId'] as String?;
      }
    } catch (e) {
      debugPrint('nextClientIdProvider: orderBy clientId failed: $e');
    }
  }

  // 3. Last resort for collection: Fetch a few docs without order (no index needed)
  if (lastId == null) {
    try {
      final snapshot = await collection.limit(20).get();
      if (snapshot.docs.isNotEmpty) {
        final ids = snapshot.docs
            .map((doc) => doc.data()['clientId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        if (ids.isNotEmpty) {
          lastId = _findMaxIdInList(ids);
        }
      }
    } catch (e) {
      debugPrint('nextClientIdProvider: simple fetch failed: $e');
    }
  }

  if (lastId != null && lastId.isNotEmpty) {
    return _incrementId(lastId);
  }

  // 4. Global Counter Fallback (for fresh starts)
  final doc = await firestore.collection('counters').doc('clients').get();
  if (doc.exists) {
    final count = (doc.data()?['count'] as int? ?? 0) + 1;
    return count.toString().padLeft(4, '0');
  }

  return '0001';
});

String _findMaxIdInList(List<String> ids) {
  if (ids.isEmpty) return '';
  String bestId = ids.first;
  int maxVal = -1;
  final RegExp regExp = RegExp(r'(\d+)$');

  for (final id in ids) {
    final match = regExp.firstMatch(id);
    if (match != null) {
      final val = int.tryParse(match.group(1)!) ?? -1;
      if (val > maxVal) {
        maxVal = val;
        bestId = id;
      }
    }
  }
  return bestId;
}

String _incrementId(String lastId) {
  if (lastId.isEmpty) return '0001';

  final RegExp regExp = RegExp(r'(\d+)$');
  final match = regExp.firstMatch(lastId);

  if (match != null) {
    final String numericPart = match.group(1)!;
    final int nextValue = int.parse(numericPart) + 1;
    final String prefix = lastId.substring(
      0,
      lastId.length - numericPart.length,
    );
    // Maintain padding if numeric part starts with 0
    return prefix + nextValue.toString().padLeft(numericPart.length, '0');
  }

  // No numeric suffix, append 01
  return '${lastId}01';
}

final clientServiceProvider = Provider((ref) => ClientActionService(ref));

class ClientActionService {
  final Ref _ref;
  ClientActionService(this._ref);

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
    final firestore = _ref.read(firestoreProvider);

    // Duplicate check
    final duplicate = await firestore
        .collection('clients')
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('Client ID "$clientId" already exists.');
    }

    await _ref
        .read(clientRepositoryProvider)
        .addClient(
          clientId: clientId,
          name: name,
          nickName: nickName,
          mobileNo: mobileNo,
          email: email,
          address: address,
          gender: gender,
          dateOfBirth: dateOfBirth,
          fatherName: fatherName,
          fatherContact: fatherContact,
          motherName: motherName,
          motherContact: motherContact,
          enrollmentDate: enrollmentDate ?? DateTime.now(),
          discontinueDate: discontinueDate,
        );

    _ref.invalidate(nextClientIdProvider);
  }

  Future<void> updateClient(Client client) async {
    await _ref.read(clientRepositoryProvider).updateClient(client);
    _ref.invalidate(nextClientIdProvider);
  }

  Future<void> deleteClient(String id) async {
    await _ref.read(clientRepositoryProvider).deleteClient(id);
    _ref.invalidate(nextClientIdProvider);
  }
}
