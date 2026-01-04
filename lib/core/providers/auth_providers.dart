import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/app/admin/features/auth/data/repositories/auth_repository_impl.dart';
import '/app/employee/features/auth/data/repositories/employee_auth_repository.dart';
import '/services/firebase_service.dart';
import 'notification_providers.dart';

class AuthState {
  final bool isAdminAuthenticated;
  final bool isEmployeeAuthenticated;
  final bool isLoading;
  final String? error;
  final bool mustChangePassword;
  final String? adminId;
  final String? employeeId;

  AuthState({
    this.isAdminAuthenticated = false,
    this.isEmployeeAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.mustChangePassword = false,
    this.adminId,
    this.employeeId,
  });

  bool get isAuthenticated => isAdminAuthenticated || isEmployeeAuthenticated;

  AuthState copyWith({
    bool? isAdminAuthenticated,
    bool? isEmployeeAuthenticated,
    bool? isLoading,
    String? error,
    bool? mustChangePassword,
    String? adminId,
    String? employeeId,
  }) {
    return AuthState(
      isAdminAuthenticated: isAdminAuthenticated ?? this.isAdminAuthenticated,
      isEmployeeAuthenticated:
          isEmployeeAuthenticated ?? this.isEmployeeAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      adminId: adminId ?? this.adminId,
      employeeId: employeeId ?? this.employeeId,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(ref.watch(firestoreProvider));
});

final employeeAuthRepositoryProvider = Provider(
  (ref) => EmployeeAuthRepository(),
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkPersistedAuth();
    return AuthState(isLoading: true);
  }

  Future<void> _checkPersistedAuth() async {
    final prefs = await SharedPreferences.getInstance();

    final isAdmin = prefs.getBool('is_admin_authenticated') ?? false;
    final isEmployee = prefs.getBool('is_employee_authenticated') ?? false;
    final mustChange = prefs.getBool('auth_must_change_password') ?? false;

    state = state.copyWith(
      isAdminAuthenticated: isAdmin,
      isEmployeeAuthenticated: isEmployee,
      adminId: prefs.getString('auth_admin_id'),
      employeeId: prefs.getString('auth_employee_id'),
      mustChangePassword: mustChange,
      isLoading: false,
    );

    // Update tokens if authenticated
    if (isAdmin && state.adminId != null) {
      ref
          .read(notificationServiceProvider)
          .updateToken(state.adminId!, 'admins');
    }
    if (isEmployee && state.employeeId != null) {
      ref
          .read(notificationServiceProvider)
          .updateToken(state.employeeId!, 'employees');
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await ref
          .read(authRepositoryProvider)
          .login(username, password);
      if (success) {
        final userId = await ref.read(authRepositoryProvider).getUserId();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin_authenticated', true);
        await prefs.setString('auth_admin_id', userId!);

        state = state.copyWith(
          isAdminAuthenticated: true,
          isLoading: false,
          adminId: userId,
        );

        // Save FCM Token
        ref.read(notificationServiceProvider).updateToken(userId, 'admins');

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid username or password',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> employeeLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await ref
          .read(employeeAuthRepositoryProvider)
          .login(email, password);

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_employee_authenticated', true);
        await prefs.setString('auth_employee_id', user.id);
        await prefs.setBool(
          'auth_must_change_password',
          user.mustChangePassword,
        );

        state = state.copyWith(
          isEmployeeAuthenticated: true,
          isLoading: false,
          employeeId: user.id,
          mustChangePassword: user.mustChangePassword,
        );

        // Save FCM Token
        ref.read(notificationServiceProvider).updateToken(user.id, 'employees');

        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid email or password',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> completePasswordChange(String newPassword) async {
    if (state.employeeId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(employeeAuthRepositoryProvider)
          .changePassword(state.employeeId!, newPassword);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_must_change_password', false);

      state = state.copyWith(mustChangePassword: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_authenticated', false);
    await prefs.remove('auth_admin_id');
    await ref.read(authRepositoryProvider).logout();
    state = state.copyWith(isAdminAuthenticated: false, adminId: null);
  }

  Future<void> logoutEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_employee_authenticated', false);
    await prefs.remove('auth_employee_id');
    await prefs.remove('auth_must_change_password');
    await ref.read(employeeAuthRepositoryProvider).logout();
    state = state.copyWith(
      isEmployeeAuthenticated: false,
      employeeId: null,
      mustChangePassword: false,
    );
  }

  // Keep general logout for complete exit
  Future<void> logout() async {
    await logoutAdmin();
    await logoutEmployee();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
