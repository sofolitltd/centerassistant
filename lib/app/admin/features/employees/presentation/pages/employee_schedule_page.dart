import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/models/client.dart';
import '/core/models/schedule_template.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/schedule_template_providers.dart';
import '/core/providers/time_slot_providers.dart';

class EmployeeSchedulePage extends ConsumerWidget {
  final String employeeId;

  const EmployeeSchedulePage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(allScheduleTemplatesProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final employeeAsync = ref.watch(employeeByIdProvider(employeeId));

    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

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
                onTap: () => context.go('/admin/employees'),
                child: Text(
                  'Employees',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              employeeAsync.when(
                data: (employee) => Text(
                  employee?.name ?? 'Unknown',
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
          Expanded(
            child: templatesAsync.when(
              data: (templates) => clientsAsync.when(
                data: (clients) => timeSlotsAsync.when(
                  data: (timeSlots) {
                    final clientMap = {for (var c in clients) c.id: c};

                    final relevantRules = templates
                        .expand(
                          (t) => t.rules.map(
                            (r) => {'rule': r, 'clientId': t.clientId},
                          ),
                        )
                        .where(
                          (map) =>
                              (map['rule'] as ScheduleRule).employeeId ==
                              employeeId,
                        )
                        .toList();

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
                                    minWidth:
                                        constraints.maxWidth > tableMinWidth
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
                                          label: Expanded(
                                            child: Text(
                                              slot.label,
                                              textAlign: TextAlign.center,
                                            ),
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
                                              final matches = relevantRules
                                                  .where(
                                                    (map) =>
                                                        (map['rule']
                                                                    as ScheduleRule)
                                                                .dayOfWeek ==
                                                            day &&
                                                        (map['rule']
                                                                    as ScheduleRule)
                                                                .timeSlotId ==
                                                            slot.id,
                                                  )
                                                  .toList();

                                              if (matches.isNotEmpty) {
                                                final relevantMap =
                                                    matches.first;
                                                final clientIdForRule =
                                                    relevantMap['clientId']
                                                        as String;
                                                final client =
                                                    clientMap[clientIdForRule];
                                                final rule =
                                                    relevantMap['rule']
                                                        as ScheduleRule;
                                                return DataCell(
                                                  Center(
                                                    child: Chip(
                                                      label: Text(
                                                        client?.name ??
                                                            'Unknown',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      onDeleted: () {
                                                        ref
                                                            .read(
                                                              scheduleTemplateServiceProvider,
                                                            )
                                                            .removeScheduleRule(
                                                              clientId:
                                                                  clientIdForRule,
                                                              ruleToRemove:
                                                                  rule,
                                                            );
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
                                                          _showAssignClientDialog(
                                                            context,
                                                            ref,
                                                            employeeId,
                                                            day,
                                                            slot.id,
                                                            clients,
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      const Center(child: Text('Could not load time slots')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) =>
                    const Center(child: Text('Could not load clients')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  const Center(child: Text('Could not load schedules')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignClientDialog(
    BuildContext context,
    WidgetRef ref,
    String employeeId,
    String day,
    String timeSlotId,
    List<Client> clients,
  ) {
    Client? selectedClient;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Client for $day'),
        content: DropdownButtonFormField<Client>(
          hint: const Text('Select a client'),
          onChanged: (client) => selectedClient = client,
          items: clients
              .map(
                (client) =>
                    DropdownMenuItem(value: client, child: Text(client.name)),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (selectedClient != null) {
                ref
                    .read(scheduleTemplateServiceProvider)
                    .setScheduleRule(
                      clientId: selectedClient!.id,
                      dayOfWeek: day,
                      timeSlotId: timeSlotId,
                      employeeId: employeeId,
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
