import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/leave.dart';
import '/core/models/schedule_template.dart';
import '/core/models/time_slot.dart';
import '/core/providers/auth_providers.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/schedule_template_providers.dart';
import '/core/providers/session_providers.dart';
import '/core/providers/time_slot_providers.dart';

enum EmployeeScheduleView { daily, weekly }

class EmployeeScheduleViewNotifier extends Notifier<EmployeeScheduleView> {
  @override
  EmployeeScheduleView build() => EmployeeScheduleView.daily;

  void setView(EmployeeScheduleView view) => state = view;
}

final employeeScheduleViewProvider =
    NotifierProvider<EmployeeScheduleViewNotifier, EmployeeScheduleView>(
      EmployeeScheduleViewNotifier.new,
    );

class EmployeePortalSchedulePage extends ConsumerWidget {
  const EmployeePortalSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final viewType = ref.watch(employeeScheduleViewProvider);
    final authState = ref.watch(authProvider);
    final employeeId = authState.employeeId;

    if (employeeId == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/employee/dashboard'),
                  child: Text(
                    'Overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Schedule', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  viewType == EmployeeScheduleView.daily
                      ? 'Daily Schedule'
                      : 'Weekly Overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _ViewToggleButton(
                      label: 'Daily',
                      isSelected: viewType == EmployeeScheduleView.daily,
                      onTap: () => ref
                          .read(employeeScheduleViewProvider.notifier)
                          .setView(EmployeeScheduleView.daily),
                    ),
                    const SizedBox(width: 8),
                    _ViewToggleButton(
                      label: 'Weekly',
                      isSelected: viewType == EmployeeScheduleView.weekly,
                      onTap: () => ref
                          .read(employeeScheduleViewProvider.notifier)
                          .setView(EmployeeScheduleView.weekly),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Selector (Only for Daily View)
            if (viewType == EmployeeScheduleView.daily) ...[
              _buildDateHeader(context, ref, selectedDate),
              const SizedBox(height: 24),
            ],

            viewType == EmployeeScheduleView.daily
                ? _DailyView(employeeId: employeeId, selectedDate: selectedDate)
                : _WeeklyView(employeeId: employeeId),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(DateFormat('d MMMM, yyyy').format(selectedDate)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref
                    .read(selectedDateProvider.notifier)
                    .setDate(selectedDate.subtract(const Duration(days: 1))),
              ),
              IconButton(
                icon: const Icon(LucideIcons.calendar),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    ref.read(selectedDateProvider.notifier).setDate(picked);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => ref
                    .read(selectedDateProvider.notifier)
                    .setDate(selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondary
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onSecondary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DailyView extends ConsumerWidget {
  final String employeeId;
  final DateTime selectedDate;
  const _DailyView({required this.employeeId, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(allScheduleTemplatesProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final leavesAsync = ref.watch(leavesByEntityProvider(employeeId));

    return leavesAsync.when(
      data: (leaves) {
        final isApprovedOnLeave = leaves.any(
          (l) =>
              l.status == LeaveStatus.approved &&
              l.date.year == selectedDate.year &&
              l.date.month == selectedDate.month &&
              l.date.day == selectedDate.day,
        );

        if (isApprovedOnLeave) {
          return _buildCenteredMessage(
            context,
            LucideIcons.calendarX,
            'You are on leave',
            'No schedule scheduled for this date.',
            Colors.red,
          );
        }

        return templatesAsync.when(
          data: (templates) => timeSlotsAsync.when(
            data: (timeSlots) => clientsAsync.when(
              data: (clients) {
                final dayName = DateFormat('EEEE').format(selectedDate);
                final clientMap = {for (var c in clients) c.id: c};

                final mySessions = templates
                    .expand(
                      (t) => t.rules.map(
                        (r) => {'rule': r, 'clientId': t.clientId},
                      ),
                    )
                    .where(
                      (m) =>
                          (m['rule'] as ScheduleRule).employeeId ==
                              employeeId &&
                          (m['rule'] as ScheduleRule).dayOfWeek == dayName,
                    )
                    .toList();

                if (mySessions.isEmpty) {
                  return _buildCenteredMessage(
                    context,
                    LucideIcons.calendar,
                    'No Sessions',
                    'Enjoy your day off!',
                    Colors.grey,
                  );
                }

                // Sorting handled by build list
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: timeSlots.map((slot) {
                        final sessionsInSlot = mySessions
                            .where(
                              (m) =>
                                  (m['rule'] as ScheduleRule).timeSlotId ==
                                  slot.id,
                            )
                            .toList();

                        return SizedBox(
                          width: constraints.maxWidth > 800
                              ? (constraints.maxWidth - 32) / 3
                              : constraints.maxWidth,
                          child: _buildTimeSlotColumn(
                            context,
                            slot,
                            sessionsInSlot,
                            clientMap,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildTimeSlotColumn(
    BuildContext context,
    TimeSlot slot,
    List<dynamic> sessions,
    Map<String, dynamic> clientMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: sessions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No schedule',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : Column(
                    children: sessions.map((m) {
                      final client = clientMap[m['clientId']];
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text(
                              client?.name[0] ?? '?',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          title: Text(
                            client?.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          dense: true,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredMessage(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    Color color,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(sub, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyView extends ConsumerWidget {
  final String employeeId;
  const _WeeklyView({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(allScheduleTemplatesProvider);
    final clientsAsync = ref.watch(clientsProvider);
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

    return templatesAsync.when(
      data: (templates) => clientsAsync.when(
        data: (clients) => timeSlotsAsync.when(
          data: (timeSlots) {
            final clientMap = {for (var c in clients) c.id: c};
            final myRules = templates
                .expand(
                  (t) =>
                      t.rules.map((r) => {'rule': r, 'clientId': t.clientId}),
                )
                .where(
                  (m) => (m['rule'] as ScheduleRule).employeeId == employeeId,
                )
                .toList();

            return Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double tableMinWidth = (timeSlots.length + 1) * 160.0;

                  Widget table = DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    columnSpacing: 24,
                    border: TableBorder.all(color: Colors.grey.shade200),
                    columns: [
                      const DataColumn(
                        label: Text(
                          'Day',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (var slot in timeSlots)
                        DataColumn(
                          label: Text(
                            '${slot.startTime} - ${slot.endTime}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                    rows: days.map((day) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...timeSlots.map((slot) {
                            final matches = myRules
                                .where(
                                  (m) =>
                                      (m['rule'] as ScheduleRule).dayOfWeek ==
                                          day &&
                                      (m['rule'] as ScheduleRule).timeSlotId ==
                                          slot.id,
                                )
                                .toList();

                            if (matches.isEmpty) {
                              return const DataCell(
                                Center(
                                  child: Text(
                                    '-',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            final client = clientMap[matches.first['clientId']];
                            return DataCell(
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    client?.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  );

                  if (constraints.maxWidth < tableMinWidth) {
                    return Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: tableMinWidth),
                          child: table,
                        ),
                      ),
                    );
                  } else {
                    return SizedBox(width: double.infinity, child: table);
                  }
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
