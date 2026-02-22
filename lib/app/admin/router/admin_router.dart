import 'package:center_assistant/app/admin/features/billing/presentation/pages/all_transactions_page.dart';
import 'package:center_assistant/app/admin/features/dashboard/presentation/pages/admin_report_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/admin/features/auth/presentation/pages/admin_login_page.dart';
import '/app/admin/features/clients/presentation/pages/add_client_page.dart';
import '/app/admin/features/clients/presentation/pages/client_details_page.dart';
import '/app/admin/features/clients/presentation/pages/client_page.dart';
import '/app/admin/features/clients/presentation/pages/edit_client_page.dart';
import '/app/admin/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '/app/admin/features/employees/presentation/pages/access_portal_page.dart';
import '/app/admin/features/employees/presentation/pages/add_employee_page.dart';
import '/app/admin/features/employees/presentation/pages/department_page.dart';
import '/app/admin/features/employees/presentation/pages/edit_employee_page.dart';
import '/app/admin/features/employees/presentation/pages/employee_details_page.dart';
import '/app/admin/features/employees/presentation/pages/employee_page.dart';
import '/app/admin/features/layout/presentation/pages/admin_layout_page.dart';
import '/app/admin/features/leave/presentation/pages/leave_management_page.dart';
import '/app/admin/features/settings/presentation/pages/holiday_page.dart';
import '/app/admin/features/settings/presentation/pages/service_rates_page.dart';
import '/app/admin/features/time_slots/presentation/pages/time_slot_page.dart';
import '/app/admin/features/utilization/presentation/pages/therapist_utilization_page.dart';
import '/core/constants/app_constants.dart';
import '../features/contact/presentation/pages/employee_contact_page.dart';
import '../features/schedule/presentation/pages/add/add_schedule_page.dart';
import '../features/schedule/presentation/pages/edit/edit_schedule_page.dart';
import '../features/schedule/presentation/pages/home/schedule_all_page.dart';

List<RouteBase> adminRoutes(Widget Function(Widget) wrapWithSelectionArea) {
  return [
    GoRoute(
      path: '/admin/login',
      pageBuilder: (context, state) => NoTransitionPage(
        child: Title(
          title: 'Admin Login | ${AppConstants.appName}',
          color: Colors.black,
          child: wrapWithSelectionArea(const AdminLoginPage()),
        ),
      ),
    ),

    GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),

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
              title: 'Dashboard | ${AppConstants.appName}',
              color: Colors.black,
              child: const AdminDashboardPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/reports',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Reports | ${AppConstants.appName}',
              color: Colors.black,
              child: const AdminReportPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/schedule',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: Title(
                title: 'Schedule | ${AppConstants.appName}',
                color: Colors.black,
                child: const ScheduleAllPage(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/schedule/add',
          pageBuilder: (context, state) {
            final clientId = state.uri.queryParameters['clientId'];
            final timeSlotId = state.uri.queryParameters['timeSlotId'];
            final employeeId = state.uri.queryParameters['employeeId'];

            return NoTransitionPage(
              child: Title(
                title: 'Add Schedule | ${AppConstants.appName}',
                color: Colors.black,
                child: AddSchedulePage(
                  initialClientId: clientId,
                  initialTimeSlotId: timeSlotId,
                  initialEmployeeId: employeeId,
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/admin/schedule/:sessionId/edit',
          pageBuilder: (context, state) {
            final sessionId = state.pathParameters['sessionId']!;
            return NoTransitionPage(
              child: Title(
                title: 'Edit Schedule | ${AppConstants.appName}',
                color: Colors.black,
                child: EditSchedulePage(sessionId: sessionId),
              ),
            );
          },
        ),

        ///  employee directory
        GoRoute(
          path: '/admin/employees',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Employees | ${AppConstants.appName}',
              color: Colors.black,
              child: const EmployeePage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/employees/add',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Add Employee | ${AppConstants.appName}',
              color: Colors.black,
              child: const AddEmployeePage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/employees/:id/edit',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Edit Employee | ${AppConstants.appName}',
              color: Colors.black,
              child: EditEmployeePage(employeeId: state.pathParameters['id']!),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/employees/invite',
          pageBuilder: (context, state) {
            final userId = state.uri.queryParameters['userId'];
            return NoTransitionPage(
              child: Title(
                title: 'Invite Employee | ${AppConstants.appName}',
                color: Colors.black,
                child: AccessPortalPage(userId: userId),
              ),
            );
          },
        ),

        // Tabbed details route (Details, Schedule, Leave)
        GoRoute(
          path: '/admin/employees/:employeeId/:tab',
          pageBuilder: (context, state) {
            final employeeId = state.pathParameters['employeeId']!;
            final tab = state.pathParameters['tab'] ?? 'details';
            return NoTransitionPage(
              child: EmployeeDetailsPage(
                employeeId: employeeId,
                initialTab: tab,
              ),
            );
          },
        ),

        GoRoute(
          path: '/admin/employees/:employeeId',
          redirect: (context, state) =>
              '/admin/employees/${state.pathParameters['employeeId']}/details',
        ),

        // client directory
        GoRoute(
          path: '/admin/clients',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Clients | ${AppConstants.appName}',
              color: Colors.black,
              child: const ClientPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/clients/add',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Add Client | ${AppConstants.appName}',
              color: Colors.black,
              child: const AddClientPage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/clients/:id/edit',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Edit Client | ${AppConstants.appName}',
              color: Colors.black,
              child: EditClientPage(clientId: state.pathParameters['id']!),
            ),
          ),
        ),

        // Tabbed details route (Details, Schedule, Billing, Absence)
        GoRoute(
          path: '/admin/clients/:clientId/:tab',
          pageBuilder: (context, state) {
            final clientId = state.pathParameters['clientId']!;
            final tab = state.pathParameters['tab'] ?? 'details';
            return NoTransitionPage(
              child: ClientDetailsPage(clientId: clientId, initialTab: tab),
            );
          },
        ),

        GoRoute(
          path: '/admin/clients/:clientId',
          redirect: (context, state) =>
              '/admin/clients/${state.pathParameters['clientId']}/details',
        ),

        /// settings
        GoRoute(
          path: '/admin/settings/departments',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Departments | ${AppConstants.appName}',
              color: Colors.black,
              child: const DepartmentManagementPage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/settings/time-slots',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Time Slots | ${AppConstants.appName}',
              color: Colors.black,
              child: const TimeSlotPage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/settings/holidays',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Holidays | ${AppConstants.appName}',
              color: Colors.black,
              child: const HolidayPage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/settings/service-charges',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Service Charges | ${AppConstants.appName}',
              color: Colors.black,
              child: const ServiceRatesPage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/utilization',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Therapist Utilization | ${AppConstants.appName}',
              color: Colors.black,
              child: const TherapistUtilizationPage(),
            ),
          ),
        ),

        GoRoute(
          path: '/admin/transactions',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'All Transactions | ${AppConstants.appName}',
              color: Colors.black,
              child: const AllTransactionsPage(),
            ),
          ),
        ),

        // others
        GoRoute(
          path: '/admin/contacts',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Employee Contact | ${AppConstants.appName}',
              color: Colors.black,
              child: EmployeeContactPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/leaves',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Title(
              title: 'Leave Management | ${AppConstants.appName}',
              color: Colors.black,
              child: const LeaveManagementPage(),
            ),
          ),
        ),
      ],
    ),
  ];
}
