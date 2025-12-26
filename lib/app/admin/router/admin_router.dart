import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/admin/features/auth/presentation/pages/admin_login_page.dart';
import '/app/admin/features/availability/presentation/pages/availability_page.dart';
import '/app/admin/features/clients/presentation/pages/add_client_page.dart';
import '/app/admin/features/clients/presentation/pages/client_page.dart';
import '/app/admin/features/clients/presentation/pages/client_schedule_page.dart';
import '/app/admin/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '/app/admin/features/employees/presentation/pages/access_portal_page.dart';
import '/app/admin/features/employees/presentation/pages/add_employee_page.dart';
import '/app/admin/features/employees/presentation/pages/employee_page.dart';
import '/app/admin/features/employees/presentation/pages/employee_schedule_page.dart';
import '/app/admin/features/layout/presentation/pages/admin_layout_page.dart';
import '/app/admin/features/sessions/presentation/pages/schedule_page.dart';
import '/app/admin/features/time_slots/presentation/pages/add_time_slot_page.dart';
import '/app/admin/features/time_slots/presentation/pages/time_slot_page.dart';
import '/core/models/leave.dart';

List<RouteBase> adminRoutes(Widget Function(Widget) wrapWithSelectionArea) {
  return [
    GoRoute(
      path: '/admin/login',
      pageBuilder: (context, state) => NoTransitionPage(
        child: Title(
          title: 'Admin Login | Center Assistant',
          color: Colors.black,
          child: wrapWithSelectionArea(const AdminLoginPage()),
        ),
      ),
    ),

    GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),

    //
    ShellRoute(
      pageBuilder: (context, state, child) {
        return NoTransitionPage(
          child: wrapWithSelectionArea(AdminLayoutPage(child: child)),
        );
      },
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Overview | Center Assistant',
              color: Colors.black,
              child: const AdminDashboardPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/schedule',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Schedule | Center Assistant',
              color: Colors.black,
              child: const SchedulePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/employees',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Employees | Center Assistant',
              color: Colors.black,
              child: const EmployeePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/employees/:employeeId/schedule',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Employee Schedule | Center Assistant',
              color: Colors.black,
              child: EmployeeSchedulePage(
                employeeId: state.pathParameters['employeeId']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/employees/:employeeId/availability',
          pageBuilder: (context, state) {
            final employeeId = state.pathParameters['employeeId']!;
            final employeeName =
                state.uri.queryParameters['name'] ?? 'Employee';
            return NoTransitionPage(
              child: Title(
                title: 'Employee Availability | Center Assistant',
                color: Colors.black,
                child: AvailabilityPage(
                  entityId: employeeId,
                  entityType: LeaveEntityType.employee,
                  entityName: employeeName,
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/employees/add',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Add Employee | Center Assistant',
              color: Colors.black,
              child: const AddEmployeePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/employees/invite',
          pageBuilder: (context, state) {
            final userId = state.uri.queryParameters['userId'];
            return NoTransitionPage(
              child: Title(
                title: 'Invite Employee | Center Assistant',
                color: Colors.black,
                child: AccessPortalPage(userId: userId),
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/clients',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Clients | Center Assistant',
              color: Colors.black,
              child: const ClientPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/clients/:clientId/schedule',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Client Schedule | Center Assistant',
              color: Colors.black,
              child: ClientSchedulePage(
                clientId: state.pathParameters['clientId']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/clients/:clientId/availability',
          pageBuilder: (context, state) {
            final clientId = state.pathParameters['clientId']!;
            final clientName = state.uri.queryParameters['name'] ?? 'Client';
            return NoTransitionPage(
              child: Title(
                title: 'Client Availability | Center Assistant',
                color: Colors.black,
                child: AvailabilityPage(
                  entityId: clientId,
                  entityType: LeaveEntityType.client,
                  entityName: clientName,
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/clients/add',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Add Client | Center Assistant',
              color: Colors.black,
              child: const AddClientPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/time-slots',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Time Slots | Center Assistant',
              color: Colors.black,
              child: const TimeSlotPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/time-slots/add',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Add Time Slot | Center Assistant',
              color: Colors.black,
              child: const AddTimeSlotPage(),
            ),
          ),
        ),
      ],
    ),
  ];
}
