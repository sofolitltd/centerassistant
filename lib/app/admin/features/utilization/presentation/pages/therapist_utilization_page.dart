import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';
import '/core/models/session.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';

class TherapistUtilizationPage extends ConsumerWidget {
  const TherapistUtilizationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final monthlySessionsAsync = ref.watch(allMonthlySessionsProvider);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              _buildBreadcrumbs(context),
              const SizedBox(height: 16),

              // Title
              Text(
                'Therapist Utilization: $monthName',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1100;

                  if (isWide) {
                    // LG: 2 columns. Left: Tabs, Right: Summary (Vertical)
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildTabSection(context)),
                        const SizedBox(width: 32),
                        SizedBox(
                          width: 300,
                          child: _buildSummaryContent(
                            context,
                            monthlySessionsAsync,
                            clientsAsync,
                            isRow: false,
                          ),
                        ),
                      ],
                    );
                  } else {
                    // SM/MD: Column. Top: Summary (Row), Bottom: Tabs
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryContent(
                          context,
                          monthlySessionsAsync,
                          clientsAsync,
                          isRow: true,
                        ),
                        const SizedBox(height: 32),
                        _buildTabSection(context),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/admin/dashboard'),
          child: const Text(
            'Admin',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        InkWell(
          onTap: () => context.go('/admin/dashboard'),
          child: const Text(
            'Dashboard',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        const Text(
          'Utilization',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryContent(
    BuildContext context,
    AsyncValue<List<Session>> sessionsAsync,
    AsyncValue<dynamic> clientsAsync, {
    required bool isRow,
  }) {
    return sessionsAsync.when(
      data: (sessions) {
        final totalSessions = sessions.length;
        final totalHours = sessions.fold<double>(
          0,
          (sum, s) => sum + s.totalDuration,
        );

        final items = [
          _buildSummaryCard(
            'Monthly Sessions',
            totalSessions.toString(),
            LucideIcons.calendarCheck,
            Colors.blueAccent,
          ),
          clientsAsync.when(
            data: (clients) => _buildSummaryCard(
              'Active Clients',
              (clients as List).length.toString(),
              LucideIcons.users,
              Colors.green,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          _buildSummaryCard(
            'Total Clinical Hours',
            '${totalHours.toStringAsFixed(1)}h',
            LucideIcons.clock,
            Colors.orange,
          ),
        ];

        if (isRow) {
          return Row(
            children: items
                .map(
                  (widget) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: widget,
                    ),
                  ),
                )
                .toList(),
          );
        } else {
          return Column(
            children: items
                .map(
                  (widget) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: widget,
                  ),
                )
                .toList(),
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'All (Month)'),
              Tab(text: 'Week 1'),
              Tab(text: 'Week 2'),
              Tab(text: 'Week 3'),
              Tab(text: 'Week 4'),
            ],
          ),
          const SizedBox(height: 24),
          const SizedBox(
            height: 800,
            child: TabBarView(
              children: [
                _WeeklyUtilizationView(weekOffset: null),
                _WeeklyUtilizationView(weekOffset: 0),
                _WeeklyUtilizationView(weekOffset: 1),
                _WeeklyUtilizationView(weekOffset: 2),
                _WeeklyUtilizationView(weekOffset: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyUtilizationView extends ConsumerWidget {
  final int? weekOffset;
  const _WeeklyUtilizationView({required this.weekOffset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final schedulableDeptsAsync = ref.watch(schedulableDepartmentsProvider);
    final monthlySessionsAsync = ref.watch(allMonthlySessionsProvider);

    return monthlySessionsAsync.when(
      data: (sessions) => employeesAsync.when(
        data: (employees) => schedulableDeptsAsync.when(
          data: (schedulableDepts) {
            final now = DateTime.now();
            final firstOfMonth = DateTime(now.year, now.month, 1);

            List<Session> displaySessions;
            int target;

            if (weekOffset == null) {
              displaySessions = sessions;
              target = 52; // 13 sessions per week * 4 weeks
            } else {
              final weekStart = firstOfMonth.add(
                Duration(days: 7 * weekOffset!),
              );
              final weekEnd = weekStart.add(const Duration(days: 7));

              displaySessions = sessions.where((s) {
                final date = s.date.toDate();
                return date.isAfter(
                      weekStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    date.isBefore(weekEnd);
              }).toList();
              target = 13;
            }

            final filteredEmployees = employees
                .where((e) => schedulableDepts.contains(e.department))
                .toList();

            final Map<String, int> workloadCount = {};
            final Map<String, double> workloadHours = {};
            for (final s in displaySessions) {
              for (final sv in s.services) {
                workloadCount[sv.employeeId] =
                    (workloadCount[sv.employeeId] ?? 0) + 1;
                workloadHours[sv.employeeId] =
                    (workloadHours[sv.employeeId] ?? 0.0) + sv.duration;
              }
            }

            filteredEmployees.sort(
              (a, b) => (workloadCount[b.id] ?? 0).compareTo(
                workloadCount[a.id] ?? 0,
              ),
            );

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final emp = filteredEmployees[index];
                final count = workloadCount[emp.id] ?? 0;
                final hours = workloadHours[emp.id] ?? 0.0;
                return _buildTherapistCard(emp, count, hours, target);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTherapistCard(
    Employee emp,
    int count,
    double hours,
    int target,
  ) {
    final percentage = (count / target).clamp(0.0, 1.0);

    Color color = Colors.blue;
    if (count > target)
      color = Colors.red;
    else if (count >= (target * 0.85).round())
      color = Colors.orange;
    else if (count >= (target * 0.4).round())
      color = Colors.green;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      emp.department,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),

                //
                Row(
                  children: [
                    //
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Session: $count',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ),

                    const SizedBox(width: 8),
                    //
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Hour: ${hours.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Spacer(),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
