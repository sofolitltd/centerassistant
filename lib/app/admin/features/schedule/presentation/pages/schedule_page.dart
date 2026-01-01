import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/session.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import '../widgets/add_session_dialog.dart';
import '../widgets/session_card.dart';

enum ScheduleViewType { all, employee }

class ScheduleViewTypeNotifier extends Notifier<ScheduleViewType> {
  @override
  ScheduleViewType build() => ScheduleViewType.all;

  void set(ScheduleViewType type) => state = type;
}

final scheduleViewTypeProvider =
    NotifierProvider<ScheduleViewTypeNotifier, ScheduleViewType>(
      ScheduleViewTypeNotifier.new,
    );

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final viewType = ref.watch(scheduleViewTypeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedules',
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
                    'Schedule',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(selectedDate),
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                        Text(
                          DateFormat('d MMMM, yyyy').format(selectedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (isMobile) const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            final newDate = selectedDate.subtract(
                              const Duration(days: 1),
                            );
                            ref
                                .read(selectedDateProvider.notifier)
                                .setDate(newDate);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              ref
                                  .read(selectedDateProvider.notifier)
                                  .setDate(pickedDate);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            final newDate = selectedDate.add(
                              const Duration(days: 1),
                            );
                            ref
                                .read(selectedDateProvider.notifier)
                                .setDate(newDate);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    _ViewToggleButton(
                      label: 'All Sessions',
                      isSelected: viewType == ScheduleViewType.all,
                      onTap: () => ref
                          .read(scheduleViewTypeProvider.notifier)
                          .set(ScheduleViewType.all),
                    ),
                    const SizedBox(width: 12),
                    _ViewToggleButton(
                      label: 'Employee View',
                      isSelected: viewType == ScheduleViewType.employee,
                      onTap: () => ref
                          .read(scheduleViewTypeProvider.notifier)
                          .set(ScheduleViewType.employee),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              viewType == ScheduleViewType.all
                  ? const _AllSessionsView()
                  : const _EmployeeView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AllSessionsView extends ConsumerWidget {
  const _AllSessionsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleViewAsync = ref.watch(scheduleViewProvider);
    return scheduleViewAsync.when(
      data: (scheduleView) {
        if (scheduleView.timeSlots.isEmpty) {
          return const Center(child: Text('No time slots created.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final int columnCount = scheduleView.timeSlots.length;
            const double columnWidth = 350.0;
            const double spacing = 16.0;
            final double totalContentWidth =
                (columnCount * columnWidth) + ((columnCount - 1) * spacing);

            if (totalContentWidth <= constraints.maxWidth) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < columnCount; i++) ...[
                    Expanded(
                      child: _buildTimeSlotColumn(
                        context,
                        ref,
                        scheduleView.timeSlots[i],
                        scheduleView.sessionsByTimeSlot[scheduleView
                                .timeSlots[i]
                                .id] ??
                            [],
                      ),
                    ),
                    if (i < columnCount - 1) const SizedBox(width: spacing),
                  ],
                ],
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < columnCount; i++) ...[
                      SizedBox(
                        width: columnWidth,
                        child: _buildTimeSlotColumn(
                          context,
                          ref,
                          scheduleView.timeSlots[i],
                          scheduleView.sessionsByTimeSlot[scheduleView
                                  .timeSlots[i]
                                  .id] ??
                              [],
                        ),
                      ),
                      if (i < columnCount - 1) const SizedBox(width: spacing),
                    ],
                  ],
                ),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('An error occurred: $err')),
    );
  }

  Widget _buildTimeSlotColumn(
    BuildContext context,
    WidgetRef ref,
    dynamic timeSlot,
    List<SessionCardData> sessions,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeSlot.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeSlot.startTime.isNotEmpty &&
                          timeSlot.endTime.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${timeSlot.startTime} - ${timeSlot.endTime}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () =>
                      _showAddSessionDialog(context, ref, timeSlot.id),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sessions.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No schedule',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ]
                  : sessions
                        .map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SessionCard(
                              session: session,
                              timeSlotId: timeSlot.id,
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(
    BuildContext context,
    WidgetRef ref,
    String timeSlotId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddSessionDialog(timeSlotId: timeSlotId),
    );
  }
}

class _EmployeeView extends ConsumerWidget {
  const _EmployeeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleViewAsync = ref.watch(scheduleViewProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return scheduleViewAsync.when(
      data: (scheduleView) => employeesAsync.when(
        data: (employees) {
          return LayoutBuilder(
            builder: (context, constraints) {
              const double tableMinWidth = 800.0;

              Widget table = DataTable(
                columnSpacing: 24,
                border: TableBorder.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'Employee',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (var slot in scheduleView.timeSlots)
                    DataColumn(
                      label: Text(
                        slot.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
                rows: employees.map((employee) {
                  return DataRow(
                    cells:
                        [
                          DataCell(
                            Text(
                              employee.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ] +
                        scheduleView.timeSlots.map((slot) {
                          final sessions =
                              scheduleView.sessionsByTimeSlot[slot.id] ?? [];
                          final employeeSessions = sessions
                              .where((s) => s.employeeId == employee.id)
                              .toList();

                          if (employeeSessions.isEmpty) {
                            return const DataCell(
                              Text('-', style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: employeeSessions.map((s) {
                                  final color = _getSessionColor(s.sessionType);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            s.sessionType == SessionType.regular
                                            ? Colors.grey.withValues(alpha: 0.2)
                                            : _getStatusBorderColor(
                                                s.sessionType,
                                              ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      s.clientName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration:
                                            s.sessionType ==
                                                SessionType.cancelled
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                }).toList(),
              );

              if (constraints.maxWidth < tableMinWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: tableMinWidth),
                    child: table,
                  ),
                );
              } else {
                return SizedBox(width: double.infinity, child: table);
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load employees')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) =>
          const Center(child: Text('Could not load schedule data')),
    );
  }

  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.regular:
        return const Color(0xFFF3F4F6); // Neutral gray-ish
      case SessionType.cover:
        return const Color(0xFFFFF7ED); // Light orange
      case SessionType.makeup:
        return const Color(0xFFEFF6FF); // Light blue
      case SessionType.extra:
        return const Color(0xFFF0FDF4); // Light green
      case SessionType.cancelled:
        return const Color(0xFFFEF2F2); // Light red
      case SessionType.completed:
        return const Color(0xFFF0FDF4); // Also light green
    }
  }

  Color _getStatusBorderColor(SessionType type) {
    switch (type) {
      case SessionType.regular:
        return Colors.transparent;
      case SessionType.cover:
        return Colors.orange.shade200;
      case SessionType.makeup:
        return Colors.blue.shade200;
      case SessionType.extra:
        return Colors.green.shade200;
      case SessionType.cancelled:
        return Colors.red.shade200;
      case SessionType.completed:
        return Colors.green.shade300;
    }
  }
}
