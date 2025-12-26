import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String mobileNo;
  final String email;
  final String address;
  final String gender;
  final DateTime dateOfBirth;
  final String image;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.mobileNo,
    required this.email,
    required this.address,
    required this.gender,
    required this.dateOfBirth,
    this.image = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobileNo': mobileNo,
      'email': email,
      'address': address,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'image': image,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Client.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Client(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      mobileNo: data['mobileNo'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      image: data['image'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
