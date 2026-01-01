import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '/core/models/leave.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/time_slot_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final leavesAsync = ref.watch(allLeavesProvider);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/admin/layout'),
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
              const SizedBox(height: 24),

              //
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
                      //
                      switch (index) {
                        case 0:
                          return _buildSummaryCard(
                            context: context,
                            title: 'Total Employees',
                            asyncValue: employeesAsync,
                            icon: Icons.group,
                            onTap: () => context.go('/admin/employees'),
                          );
                        case 1:
                          return _buildSummaryCard(
                            context: context,
                            title: 'Total Clients',
                            asyncValue: clientsAsync,
                            icon: Icons.person,
                            onTap: () => context.go('/admin/clients'),
                          );
                        case 2:
                          return _buildSummaryCard(
                            context: context,
                            title: 'Total Time Slots',
                            asyncValue: timeSlotsAsync,
                            icon: Icons.schedule,
                            onTap: () => context.go('/admin/time-slots'),
                          );
                        case 3:
                          final pendingLeavesAsync = leavesAsync.whenData(
                            (leaves) => leaves
                                .where((l) => l.status == LeaveStatus.pending)
                                .toList(),
                          );
                          return _buildSummaryCard(
                            context: context,
                            title: 'Pending Leaves',
                            asyncValue: pendingLeavesAsync,
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
    required AsyncValue<List<dynamic>> asyncValue,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        // borderRadius: BorderRadius.circular(8),
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
                    asyncValue.when(
                      data: (items) => Text(
                        items.length.toString(),
                        style: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, stack) => const Text(
                        '0',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
