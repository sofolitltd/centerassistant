import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/app/admin/router/admin_router.dart';
import '/app/employee/router/employee_router.dart';
import '/app/landing/presentation/pages/landing_page.dart';
import '/core/providers/auth_providers.dart';

/// A notifier that triggers GoRouter to refresh its redirects when the auth state changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  Widget wrapWithSelectionArea(Widget child) {
    if (kIsWeb) {
      return SelectionArea(child: child);
    }
    return child;
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // If the auth state is still loading (checking persistence), don't redirect yet.
      if (authState.isLoading) return null;

      final path = state.uri.path;

      final isAdminLogin = path == '/admin/login';
      final isEmployeeLogin = path == '/employee/login';
      final isAdminRoute = path.startsWith('/admin');
      final isEmployeeRoute = path.startsWith('/employee');

      // 1. Unauthenticated checks (Role specific)
      if (isAdminRoute && !isAdminLogin && !authState.isAdminAuthenticated) {
        return '/admin/login';
      }

      if (isEmployeeRoute &&
          !isEmployeeLogin &&
          !authState.isEmployeeAuthenticated) {
        return '/employee/login';
      }

      // 2. Authenticated login page bypass
      if (isAdminLogin && authState.isAdminAuthenticated) {
        return '/admin/dashboard';
      }

      if (isEmployeeLogin && authState.isEmployeeAuthenticated) {
        if (authState.mustChangePassword) return '/employee/change-password';
        return '/employee/dashboard';
      }

      // 3. Base path redirects
      if (path == '/admin' && authState.isAdminAuthenticated) {
        return '/admin/dashboard';
      }
      if (path == '/employee' && authState.isEmployeeAuthenticated) {
        return '/employee/dashboard';
      }

      // 4. Employee password change enforcement
      if (isEmployeeRoute &&
          authState.isEmployeeAuthenticated &&
          authState.mustChangePassword &&
          path != '/employee/change-password') {
        return '/employee/change-password';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: wrapWithSelectionArea(const LandingPage())),
      ),

      ...adminRoutes(wrapWithSelectionArea),
      ...employeeRoutes(wrapWithSelectionArea),
    ],
  );
});
