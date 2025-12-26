import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/employee/features/auth/presentation/pages/change_password_page.dart';
import '/app/employee/features/auth/presentation/pages/employee_login_page.dart';
import '/app/employee/features/clients/presentation/pages/employee_clients_page.dart';
import '/app/employee/features/contact/presentation/pages/employee_contact_page.dart';
import '/app/employee/features/dashboard/presentation/pages/employee_dashboard_page.dart';
import '/app/employee/features/layout/presentation/pages/employee_layout_page.dart';
import '/app/employee/features/leave/presentation/pages/employee_leave_page.dart';
import '/app/employee/features/profile/presentation/pages/employee_profile_page.dart';
import '/app/employee/features/schedule/presentation/pages/employee_schedule_page.dart';
import '/app/employee/features/settings/presentation/pages/employee_settings_page.dart';
import '/app/employee/features/support/presentation/pages/employee_support_page.dart';

List<RouteBase> employeeRoutes(Widget Function(Widget) wrapWithSelectionArea) {
  return [
    GoRoute(
      path: '/employee/login',
      pageBuilder: (context, state) => NoTransitionPage(
        child: wrapWithSelectionArea(const EmployeeLoginPage()),
      ),
    ),
    GoRoute(
      path: '/employee/change-password',
      pageBuilder: (context, state) => NoTransitionPage(
        child: wrapWithSelectionArea(const ChangePasswordPage()),
      ),
    ),

    //
    ShellRoute(
      builder: (context, state, child) =>
          wrapWithSelectionArea(EmployeeLayoutPage(child: child)),
      routes: [
        GoRoute(
          path: '/employee/dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeDashboardPage()),
        ),
        GoRoute(
          path: '/employee/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeProfilePage()),
        ),
        GoRoute(
          path: '/employee/schedule',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeePortalSchedulePage()),
        ),
        GoRoute(
          path: '/employee/clients',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeClientsPage()),
        ),
        GoRoute(
          path: '/employee/contact',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeContactPage()),
        ),
        GoRoute(
          path: '/employee/leave',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeLeavePage()),
        ),
        GoRoute(
          path: '/employee/support',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeSupportPage()),
        ),
        GoRoute(
          path: '/employee/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EmployeeSettingsPage()),
        ),
      ],
    ),
  ];
}
