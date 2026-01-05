import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/models/employee.dart';
import '/core/models/schedule_template.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/schedule_template_providers.dart';
import '/core/providers/time_slot_providers.dart';

class ClientSchedulePage extends ConsumerWidget {
  final String clientId;

  const ClientSchedulePage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Schedule',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
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
              InkWell(
                onTap: () => context.go('/admin/clients'),
                child: Text(
                  'Clients',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              clientAsync.when(
                data: (client) => Text(
                  client?.name ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                loading: () => const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const Text('Error'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Expanded(child: WeeklyScheduleGrid()),
        ],
      ),
    );
  }
}

class WeeklyScheduleGrid extends ConsumerStatefulWidget {
  const WeeklyScheduleGrid({super.key});

  @override
  ConsumerState<WeeklyScheduleGrid> createState() => _WeeklyScheduleGridState();
}

class _WeeklyScheduleGridState extends ConsumerState<WeeklyScheduleGrid> {
  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final clientId = uri.pathSegments[2];

    final scheduleAsync = ref.watch(scheduleTemplateProvider(clientId));
    final allTemplatesAsync = ref.watch(allScheduleTemplatesProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);

    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return timeSlotsAsync.when(
      skipLoadingOnRefresh: true,
      data: (timeSlots) => employeesAsync.when(
        skipLoadingOnRefresh: true,
        data: (employees) => allTemplatesAsync.when(
          skipLoadingOnRefresh: true,
          data: (allTemplates) => scheduleAsync.when(
            skipLoadingOnRefresh: true,
            data: (template) {
              final rules = template?.rules ?? [];
              final employeeMap = {for (var t in employees) t.id: t};

              return Align(
                alignment: Alignment.topCenter,
                child: Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tableMinWidth =
                          (timeSlots.length + 1) * 150.0;

                      return Scrollbar(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth > tableMinWidth
                                  ? constraints.maxWidth
                                  : tableMinWidth,
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade50,
                              ),
                              columnSpacing: 24,
                              border: TableBorder.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              columns: [
                                const DataColumn(label: Text('Day')),
                                for (var slot in timeSlots)
                                  DataColumn(
                                    label: Text(
                                      slot.label,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                              rows: days.map((day) {
                                return DataRow(
                                  cells:
                                      [
                                        DataCell(
                                          Text(
                                            day,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ] +
                                      timeSlots.map((slot) {
                                        final rule = rules.firstWhere(
                                          (r) =>
                                              r.dayOfWeek == day &&
                                              r.timeSlotId == slot.id,
                                          orElse: () => ScheduleRule(
                                            dayOfWeek: '',
                                            timeSlotId: '',
                                            employeeId: '',
                                          ),
                                        );

                                        if (rule.employeeId.isNotEmpty) {
                                          final employee =
                                              employeeMap[rule.employeeId];
                                          return DataCell(
                                            Center(
                                              child: Chip(
                                                label: Text(
                                                  employee?.name ?? 'Unknown',
                                                ),
                                                onDeleted: () async {
                                                  final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text(
                                                        'Remove Assignment',
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to remove this employee from this session?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          child: const Text(
                                                            'Remove',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirmed == true) {
                                                    ref
                                                        .read(
                                                          scheduleTemplateServiceProvider,
                                                        )
                                                        .removeScheduleRule(
                                                          clientId: clientId,
                                                          ruleToRemove: rule,
                                                        );
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        } else {
                                          return DataCell(
                                            Center(
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    _showAssignEmployeeDialog(
                                                      context,
                                                      ref,
                                                      clientId,
                                                      day,
                                                      slot.id,
                                                      employees,
                                                      allTemplates,
                                                    ),
                                              ),
                                            ),
                                          );
                                        }
                                      }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading schedule: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) =>
              const Center(child: Text('Error loading templates')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load employees')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Could not load time slots')),
    );
  }

  void _showAssignEmployeeDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
    String day,
    String timeSlotId,
    List<Employee> employees,
    List<ScheduleTemplate> allTemplates,
  ) {
    Employee? selectedEmployee;

    // Find which employees are already busy in this specific slot
    final busyEmployeeIds = allTemplates
        .expand((t) => t.rules)
        .where((r) => r.dayOfWeek == day && r.timeSlotId == timeSlotId)
        .map((r) => r.employeeId)
        .toSet();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Container(
          constraints: BoxConstraints(minWidth: 400),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                'Assign for $day',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              //
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('departments')
              .where('isSchedulable', isEqualTo: true)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Loading...'),
              );
            }

            final schedulableDepts = snapshot.data!.docs
                .map((d) => (d.data() as Map<String, dynamic>)['name'])
                .toSet();

            final schedulableEmployees = employees
                .where((e) => schedulableDepts.contains(e.department))
                .toList();

            return DropdownButtonFormField<Employee>(
              hint: const Text('Select an employee'),
              onChanged: (employee) => selectedEmployee = employee,
              items: schedulableEmployees.map((employee) {
                final isBusy = busyEmployeeIds.contains(employee.id);
                return DropdownMenuItem(
                  value: isBusy ? null : employee,
                  enabled: !isBusy,
                  child: Text(
                    employee.name + (isBusy ? ' (Already Assigned)' : ''),
                    style: TextStyle(color: isBusy ? Colors.grey : null),
                  ),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedEmployee != null) {
                ref
                    .read(scheduleTemplateServiceProvider)
                    .setScheduleRule(
                      clientId: clientId,
                      dayOfWeek: day,
                      timeSlotId: timeSlotId,
                      employeeId: selectedEmployee!.id,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
