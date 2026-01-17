import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id; // Random Document ID
  final String clientId; // Sequential ID (e.g., 1)
  final String name;
  final String nickName;
  final String mobileNo;
  final String email;
  final String address;
  final String gender;
  final DateTime dateOfBirth;
  final String image;
  final DateTime createdAt;
  final double walletBalance; // Prepaid balance
  final double securityDeposit; // Safety money

  Client({
    required this.id,
    required this.clientId,
    required this.name,
    this.nickName = '',
    required this.mobileNo,
    required this.email,
    required this.address,
    required this.gender,
    required this.dateOfBirth,
    this.image = '',
    required this.createdAt,
    this.walletBalance = 0.0,
    this.securityDeposit = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'name': name,
      'nickName': nickName,
      'mobileNo': mobileNo,
      'email': email,
      'address': address,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'image': image,
      'createdAt': Timestamp.fromDate(createdAt),
      'walletBalance': walletBalance,
      'securityDeposit': securityDeposit,
    };
  }

  int get age {
    final now = DateTime.now();
    final birthDate = dateOfBirth;
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  factory Client.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Client(
      id: snapshot.id,
      clientId: data['clientId'] as String? ?? snapshot.id,
      name: data['name'] as String? ?? '',
      nickName: data['nickName'] as String? ?? '',
      mobileNo: data['mobileNo'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      image: data['image'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      walletBalance: (data['walletBalance'] as num? ?? 0.0).toDouble(),
      securityDeposit: (data['securityDeposit'] as num? ?? 0.0).toDouble(),
    );
  }

  Client copyWith({
    String? name,
    String? nickName,
    String? mobileNo,
    String? email,
    String? address,
    String? gender,
    DateTime? dateOfBirth,
    String? image,
    double? walletBalance,
    double? securityDeposit,
  }) {
    return Client(
      id: id,
      clientId: clientId,
      name: name ?? this.name,
      nickName: nickName ?? this.nickName,
      mobileNo: mobileNo ?? this.mobileNo,
      email: email ?? this.email,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      image: image ?? this.image,
      createdAt: createdAt,
      walletBalance: walletBalance ?? this.walletBalance,
      securityDeposit: securityDeposit ?? this.securityDeposit,
    );
  }
}
