import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client.dart';
import '/core/models/employee.dart';
import '/core/models/session.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/session_providers.dart';

class AddSessionDialog extends ConsumerStatefulWidget {
  final String timeSlotId;

  const AddSessionDialog({super.key, required this.timeSlotId});

  @override
  ConsumerState<AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends ConsumerState<AddSessionDialog> {
  Client? _selectedClient;
  Employee? _selectedEmployee;
  SessionType _sessionType = SessionType.extra;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final scheduleViewAsync = ref.watch(scheduleViewProvider);
    final leavesAsync = ref.watch(leavesByDateProvider(selectedDate));

    return AlertDialog(
      title: Container(
        constraints: const BoxConstraints(minWidth: 350),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Book New Session', style: TextStyle(fontSize: 18)),
            InkWell(
              child: const Icon(Icons.close),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: ButtonTheme(
        alignedDropdown: true,
        child: scheduleViewAsync.when(
          data: (scheduleView) => leavesAsync.when(
            data: (leaves) {
              final sessionsInSlot =
                  scheduleView.sessionsByTimeSlot[widget.timeSlotId] ?? [];

              // 1. Check Busy Status (Already in a session)
              final busyClientIds = sessionsInSlot
                  .where((s) => s.sessionType != SessionType.cancelled)
                  .map((s) => s.clientId)
                  .toSet();

              final busyEmployeeIds = sessionsInSlot
                  .where((s) => s.sessionType != SessionType.cancelled)
                  .map((s) => s.employeeId)
                  .toSet();

              // 2. Check Leave Status (Marked as off for the day)
              final leaveEntityIds = leaves.map((l) => l.entityId).toSet();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client Dropdown
                    ref
                        .watch(clientsProvider)
                        .when(
                          data: (clients) => DropdownButtonFormField<Client>(
                            hint: const Text('Select a client'),
                            initialValue: _selectedClient,
                            onChanged: (client) =>
                                setState(() => _selectedClient = client),
                            items: clients.map((client) {
                              final isBusy = busyClientIds.contains(client.id);
                              final isOnLeave = leaveEntityIds.contains(
                                client.id,
                              );

                              final bool isDisabled = isBusy || isOnLeave;
                              final String statusText = isOnLeave
                                  ? ' (On Leave)'
                                  : (isBusy ? ' (Occupied)' : '');

                              return DropdownMenuItem(
                                value: isDisabled ? null : client,
                                enabled: !isDisabled,
                                child: Text(
                                  client.name + statusText,
                                  style: TextStyle(
                                    color: isDisabled ? Colors.grey : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, _) => const Text('Error loading clients'),
                        ),
                    const SizedBox(height: 12),

                    // Employee Dropdown
                    ref
                        .watch(employeesProvider)
                        .when(
                          data: (employees) =>
                              DropdownButtonFormField<Employee>(
                                hint: const Text('Select a employee'),
                                initialValue: _selectedEmployee,
                                onChanged: (employee) => setState(
                                  () => _selectedEmployee = employee,
                                ),
                                items: employees.map((employee) {
                                  final isBusy = busyEmployeeIds.contains(
                                    employee.id,
                                  );
                                  final isOnLeave = leaveEntityIds.contains(
                                    employee.id,
                                  );

                                  final bool isDisabled = isBusy || isOnLeave;
                                  final String statusText = isOnLeave
                                      ? ' (On Leave)'
                                      : (isBusy ? ' (Busy)' : '');

                                  return DropdownMenuItem(
                                    value: isDisabled ? null : employee,
                                    enabled: !isDisabled,
                                    child: Text(
                                      employee.name + statusText,
                                      style: TextStyle(
                                        color: isDisabled ? Colors.grey : null,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, _) =>
                              const Text('Error loading employees'),
                        ),
                    const SizedBox(height: 12),

                    // Session Type
                    DropdownButtonFormField<SessionType>(
                      initialValue: _sessionType,
                      hint: const Text('Session Type'),
                      onChanged: (type) {
                        if (type != null) {
                          setState(() => _sessionType = type);
                        }
                      },
                      items: [SessionType.extra, SessionType.makeup]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.name[0].toUpperCase() +
                                    type.name.substring(1),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading availability: $e'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading schedule: $e'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedClient == null || _selectedEmployee == null)
              ? null
              : () {
                  if (_sessionType == SessionType.extra) {
                    ref
                        .read(sessionServiceProvider)
                        .bookExtraSession(
                          _selectedClient!.id,
                          widget.timeSlotId,
                          _selectedEmployee!.id,
                        );
                  } else {
                    ref
                        .read(sessionServiceProvider)
                        .bookMakeup(
                          _selectedClient!.id,
                          widget.timeSlotId,
                          _selectedEmployee!.id,
                        );
                  }
                  Navigator.pop(context);
                },
          child: const Text('Book Session'),
        ),
      ],
    );
  }
}
