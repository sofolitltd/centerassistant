abstract class IAuthRepository {
  Future<bool> login(String username, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
}
