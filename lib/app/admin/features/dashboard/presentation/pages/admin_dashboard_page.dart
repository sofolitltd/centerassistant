import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '/core/models/leave.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/session_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final todayScheduleAsync = ref.watch(scheduleViewProvider);
    final leavesAsync = ref.watch(allLeavesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/admin/dashboard'),
                    child: Text(
                      'Admin',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 900) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 2;
                  }

                  return MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _buildSummaryCard(
                            context: context,
                            title: 'Total Employees',
                            count: employeesAsync.when(
                              data: (items) => items.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            icon: Icons.group,
                            onTap: () => context.go('/admin/employees'),
                          );
                        case 1:
                          return _buildSummaryCard(
                            context: context,
                            title: 'Total Clients',
                            count: clientsAsync.when(
                              data: (items) => items.length.toString(),
                              loading: () => '...',
                              error: (_, __) => '0',
                            ),
                            icon: Icons.person,
                            onTap: () => context.go('/admin/clients'),
                          );
                        case 2:
                          final sessionCount = todayScheduleAsync.when(
                            data: (view) => view.sessionsByTimeSlot.values
                                .fold(0, (sum, list) => sum + list.length)
                                .toString(),
                            loading: () => '...',
                            error: (_, __) => '0',
                          );
                          return _buildSummaryCard(
                            context: context,
                            title: "Today's Services",
                            count: sessionCount,
                            icon: Icons.assignment_turned_in,
                            onTap: () => context.go('/admin/schedule'),
                          );
                        case 3:
                          final pendingCount = leavesAsync.when(
                            data: (leaves) => leaves
                                .where((l) => l.status == LeaveStatus.pending)
                                .length
                                .toString(),
                            loading: () => '...',
                            error: (_, __) => '0',
                          );
                          return _buildSummaryCard(
                            context: context,
                            title: 'Pending Leaves',
                            count: pendingCount,
                            icon: Icons.calendar_today,
                            iconColor: Colors.orange,
                            onTap: () => context.go('/admin/leave'),
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String count,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: (iconColor ?? Theme.of(context).primaryColor)
                      .withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count,
                      style: Theme.of(context).textTheme.headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
