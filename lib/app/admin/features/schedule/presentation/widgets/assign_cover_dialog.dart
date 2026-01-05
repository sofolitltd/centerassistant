import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/employee.dart';
import '/core/models/session.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';

class AssignCoverDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;

  const AssignCoverDialog({
    super.key,
    required this.session,
    required this.timeSlotId,
  });

  @override
  ConsumerState<AssignCoverDialog> createState() => _AssignCoverDialogState();
}

class _AssignCoverDialogState extends ConsumerState<AssignCoverDialog> {
  Employee? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    final scheduleViewAsync = ref.watch(scheduleViewProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final schedulableDeptsAsync = ref.watch(schedulableDepartmentsProvider);

    return AlertDialog(
      title: Container(
        constraints: const BoxConstraints(minWidth: 350),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Assign Cover Employee', style: TextStyle(fontSize: 18)),
            InkWell(
              child: const Icon(Icons.close),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: scheduleViewAsync.when(
        data: (scheduleView) => employeesAsync.when(
          data: (employees) => schedulableDeptsAsync.when(
            data: (schedulableDepts) {
              // 1. Filter employees to only those in schedulable departments
              final schedulableEmployees = employees
                  .where((e) => schedulableDepts.contains(e.department))
                  .toList();

              // 2. Find who is busy in this time slot WITH OTHER CLIENTS
              final busyEmployeeIds =
                  scheduleView.sessionsByTimeSlot[widget.timeSlotId]
                      ?.where(
                        (s) =>
                            s.clientId != widget.session.clientId &&
                            s.sessionType != SessionType.cancelled,
                      )
                      .map((s) => s.employeeId)
                      .toSet() ??
                  {};

              return DropdownButtonFormField<Employee>(
                hint: const Text('Select a employee'),
                initialValue: _selectedEmployee,
                onChanged: (employee) =>
                    setState(() => _selectedEmployee = employee),
                items: schedulableEmployees.map((employee) {
                  final isRegular =
                      employee.id == widget.session.templateEmployeeId;
                  final isCurrentlyAssigned =
                      employee.id == widget.session.employeeId;
                  final isBusyWithOthers = busyEmployeeIds.contains(
                    employee.id,
                  );

                  // Logic:
                  // 1. Hide the regular employee (use "Restore Regular" instead)
                  // 2. Disable if busy with another client.
                  // 3. Disable if already assigned to THIS specific session card.
                  final bool isSelectable =
                      !isRegular && !isCurrentlyAssigned && !isBusyWithOthers;

                  return DropdownMenuItem<Employee>(
                    value: isSelectable ? employee : null,
                    enabled: isSelectable,
                    child: Text(
                      employee.name +
                          (isRegular ? ' (Regular)' : '') +
                          (isBusyWithOthers ? ' (Busy)' : '') +
                          (isCurrentlyAssigned && !isRegular
                              ? ' (Current)'
                              : ''),
                      style: TextStyle(color: isSelectable ? null : Colors.grey),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedEmployee == null
              ? null
              : () {
                  ref
                      .read(sessionServiceProvider)
                      .assignCover(
                        widget.session.clientId,
                        widget.timeSlotId,
                        _selectedEmployee!.id,
                        widget.session.templateEmployeeId,
                      );
                  Navigator.pop(context);
                },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
