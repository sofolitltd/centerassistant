import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseFirestore _firestore;
  static const String _authKey = 'is_authenticated';
  static const String _roleKey = 'auth_role';
  static const String _userIdKey = 'auth_user_id';

  AuthRepositoryImpl(this._firestore);

  @override
  Future<bool> login(String username, String password) async {
    final snapshot = await _firestore
        .collection('admins')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authKey, true);
      await prefs.setString(_roleKey, 'admin');
      await prefs.setString(_userIdKey, snapshot.docs.first.id);
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
}
