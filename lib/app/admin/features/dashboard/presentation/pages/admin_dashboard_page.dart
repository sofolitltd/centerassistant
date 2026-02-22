import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';
import '/core/models/leave.dart';
import '/core/models/session.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/session_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final schedulableDeptsAsync = ref.watch(schedulableDepartmentsProvider);
    final todayScheduleAsync = ref.watch(scheduleViewProvider);
    final leavesAsync = ref.watch(allLeavesProvider);

    final allMonthlySessionsAsync = ref.watch(allMonthlySessionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),

            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 1000;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildSectionTitle(
                              context,
                              'Therapist Monthly Load',
                              icon: LucideIcons.userCheck,
                              trailing: TextButton(
                                onPressed: () =>
                                    context.go('/admin/utilization'),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTherapistWorkloadList(
                              context,
                              allMonthlySessionsAsync,
                              employeesAsync,
                              schedulableDeptsAsync,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSectionTitle(
                              context,
                              'Session Distribution Breakdown',
                              icon: LucideIcons.pieChart,
                            ),
                            const SizedBox(height: 16),
                            _buildSessionStatusChart(
                              context,
                              allMonthlySessionsAsync,
                            ),
                            const SizedBox(height: 32),
                            _buildSectionTitle(
                              context,
                              'Operational Activity Pulse',
                              icon: LucideIcons.activity,
                            ),
                            const SizedBox(height: 16),
                            _buildOperationsCard(
                              todayScheduleAsync,
                              leavesAsync,
                              allMonthlySessionsAsync,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildSectionTitle(
                        context,
                        'Therapist Monthly Load',
                        icon: LucideIcons.userCheck,
                        trailing: TextButton(
                          onPressed: () => context.go('/admin/utilization'),
                          child: const Text(
                            'View All',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTherapistWorkloadList(
                        context,
                        allMonthlySessionsAsync,
                        employeesAsync,
                        schedulableDeptsAsync,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                        context,
                        'Session Distribution',
                        icon: LucideIcons.pieChart,
                      ),
                      const SizedBox(height: 16),
                      _buildSessionStatusChart(
                        context,
                        allMonthlySessionsAsync,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                        context,
                        'Operational Activity ',
                        icon: LucideIcons.activity,
                      ),
                      const SizedBox(height: 16),
                      _buildOperationsCard(
                        todayScheduleAsync,
                        leavesAsync,
                        allMonthlySessionsAsync,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        Text(
          'Quick overview of current operations',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTherapistWorkloadList(
    BuildContext context,
    AsyncValue<List<Session>> monthlySessionsAsync,
    AsyncValue<List<Employee>> employeesAsync,
    AsyncValue<Set<String>> schedulableDeptsAsync,
  ) {
    // For monthly view, target is 52 sessions (13 per week)
    const int targetSessions = 52;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: monthlySessionsAsync.when(
        data: (sessions) {
          return employeesAsync.when(
            data: (employees) {
              return schedulableDeptsAsync.when(
                data: (schedulableDepts) {
                  final filteredEmployees = employees
                      .where((e) => schedulableDepts.contains(e.department))
                      .toList();

                  final Map<String, int> workloadCount = {};
                  final Map<String, double> workloadHours = {};

                  for (final s in sessions) {
                    for (final sv in s.services) {
                      workloadCount[sv.employeeId] =
                          (workloadCount[sv.employeeId] ?? 0) + 1;
                      workloadHours[sv.employeeId] =
                          (workloadHours[sv.employeeId] ?? 0.0) + sv.duration;
                    }
                  }

                  filteredEmployees.sort((a, b) {
                    final aCount = workloadCount[a.id] ?? 0;
                    final bCount = workloadCount[b.id] ?? 0;
                    // Sort by highest load
                    return bCount.compareTo(aCount);
                  });

                  final displayList = filteredEmployees.take(10).toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final emp = displayList[index];
                      final count = workloadCount[emp.id] ?? 0;
                      final hours = workloadHours[emp.id] ?? 0.0;
                      final percentage = (count / targetSessions).clamp(
                        0.0,
                        1.0,
                      );

                      Color statusColor = Colors.blue;
                      if (count > targetSessions)
                        statusColor = Colors.red;
                      else if (count >= (targetSessions * 0.85).round())
                        statusColor = Colors.orange;
                      else if (count >= (targetSessions * 0.4).round())
                        statusColor = Colors.green;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  emp.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'session: $count',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'hour: ${hours.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey.shade100,
                                color: statusColor,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSessionStatusChart(
    BuildContext context,
    AsyncValue<List<Session>> monthlySessionsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: monthlySessionsAsync.when(
          data: (sessions) {
            int completed = 0;
            int cancelled = 0;
            int scheduled = 0;
            int pending = 0;

            for (var se in sessions) {
              if (se.status == SessionStatus.completed)
                completed++;
              else if (se.status == SessionStatus.cancelledClient ||
                  se.status == SessionStatus.cancelledCenter)
                cancelled++;
              else if (se.status == SessionStatus.scheduled)
                scheduled++;
              else if (se.status == SessionStatus.pending)
                pending++;
            }

            final total = (completed + cancelled + scheduled + pending)
                .toDouble();
            if (total == 0)
              return const Center(
                child: Text('No session data for this month.'),
              );

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          _buildPieSection(completed, total, Colors.green),
                          _buildPieSection(cancelled, total, Colors.red),
                          _buildPieSection(scheduled, total, Colors.blueAccent),
                          _buildPieSection(pending, total, Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Completed', completed, Colors.green),
                      const SizedBox(height: 8),
                      _buildLegendItem('Cancelled', cancelled, Colors.red),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Scheduled',
                        scheduled,
                        Colors.blueAccent,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem('Pending', pending, Colors.amber),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              const Center(child: Text('Error loading session data')),
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(int value, double total, Color color) {
    final percentage = (value / total) * 100;
    return PieChartSectionData(
      value: value.toDouble(),
      title: '${percentage.toStringAsFixed(0)}%',
      color: color,
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($value)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsCard(
    AsyncValue<dynamic> scheduleAsync,
    AsyncValue<dynamic> leavesAsync,
    AsyncValue<List<Session>> monthlySessionsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildOpItem(
              'Today\'s Sessions',
              scheduleAsync.when(
                data: (view) => view.sessionsByTimeSlot.values
                    .fold(0, (sum, list) => sum + list.length)
                    .toString(),
                loading: () => '...',
                error: (_, _) => '0',
              ),
              LucideIcons.calendar,
              Colors.blue,
            ),
            const Divider(height: 32),
            _buildOpItem(
              'Pending Leaves',
              leavesAsync.when(
                data: (leaves) => (leaves as List)
                    .where((l) => l.status == LeaveStatus.pending)
                    .length
                    .toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              LucideIcons.fileText,
              Colors.orange,
            ),
            const Divider(height: 32),
            _buildOpItem(
              'Monthly Capacity',
              monthlySessionsAsync.when(
                data: (sessions) => sessions.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              LucideIcons.layers,
              Colors.indigo,
            ),
            const Divider(height: 32),
            _buildOpItem(
              'Cancellations',
              monthlySessionsAsync.when(
                data: (sessions) => sessions
                    .where(
                      (se) =>
                          se.status == SessionStatus.cancelledClient ||
                          se.status == SessionStatus.cancelledCenter,
                    )
                    .length
                    .toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              LucideIcons.xCircle,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.black54,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildOpItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    );
  }
}
