import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/models/leave.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';

class LeaveManagementPage extends ConsumerStatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  ConsumerState<LeaveManagementPage> createState() =>
      _LeaveManagementPageState();
}

class _LeaveManagementPageState extends ConsumerState<LeaveManagementPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allLeavesAsync = ref.watch(allLeavesProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave Management',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Calendar View
            allLeavesAsync.when(
              data: (leaves) => _buildCalendarCard(theme, leaves),
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error loading calendar: $e'),
            ),

            const SizedBox(height: 32),

            Text(
              _selectedDay == null
                  ? 'All Requests'
                  : 'Requests for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            allLeavesAsync.when(
              data: (leaves) => employeesAsync.when(
                data: (employees) {
                  final employeeMap = {for (var e in employees) e.id: e};

                  // Filter by selected day if applicable
                  var filteredLeaves = leaves;
                  if (_selectedDay != null) {
                    filteredLeaves = leaves
                        .where(
                          (l) =>
                              l.date.year == _selectedDay!.year &&
                              l.date.month == _selectedDay!.month &&
                              l.date.day == _selectedDay!.day,
                        )
                        .toList();
                  }

                  // Sort by pending and cancel_requested first, then by date
                  final sortedLeaves = List<Leave>.from(filteredLeaves)
                    ..sort((a, b) {
                      bool aUrgent =
                          a.status == LeaveStatus.pending ||
                          a.status == LeaveStatus.cancel_requested;
                      bool bUrgent =
                          b.status == LeaveStatus.pending ||
                          b.status == LeaveStatus.cancel_requested;

                      if (aUrgent && !bUrgent) return -1;
                      if (!aUrgent && bUrgent) return 1;
                      return b.date.compareTo(a.date);
                    });

                  if (sortedLeaves.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No leave requests found for this selection.',
                          ),
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedLeaves.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final leave = sortedLeaves[index];
                        final employee = employeeMap[leave.entityId];

                        return ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(employee?.name[0] ?? 'E'),
                          ),
                          title: Text(
                            employee?.name ?? 'Unknown Employee',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(leave.date)} • ${leave.leaveType.name.toUpperCase()} • ${leave.duration.name.toUpperCase()} DAY',
                              ),
                              if (leave.reason != null &&
                                  leave.reason!.isNotEmpty)
                                Text(
                                  'Note: ${leave.reason}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: _buildActions(context, ref, leave),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading employees: $e'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading leaves: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(ThemeData theme, List<Leave> leaves) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              if (isSameDay(_selectedDay, selectedDay)) {
                _selectedDay = null; // Deselect if clicking same day
              } else {
                _selectedDay = selectedDay;
              }
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          eventLoader: (day) {
            return leaves
                .where(
                  (l) =>
                      l.date.year == day.year &&
                      l.date.month == day.month &&
                      l.date.day == day.day,
                )
                .toList();
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Leave leave) {
    if (leave.status == LeaveStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () =>
                _updateStatus(context, ref, leave.id, LeaveStatus.approved),
            icon: const Icon(LucideIcons.checkCircle, color: Colors.green),
            tooltip: 'Approve Request',
          ),
          IconButton(
            onPressed: () =>
                _updateStatus(context, ref, leave.id, LeaveStatus.rejected),
            icon: const Icon(LucideIcons.xCircle, color: Colors.red),
            tooltip: 'Reject Request',
          ),
        ],
      );
    }

    if (leave.status == LeaveStatus.cancel_requested) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBadge(leave.status),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                _updateStatus(context, ref, leave.id, LeaveStatus.cancelled),
            icon: const Icon(LucideIcons.check, color: Colors.orange),
            tooltip: 'Approve Cancellation',
          ),
          IconButton(
            onPressed: () =>
                _updateStatus(context, ref, leave.id, LeaveStatus.approved),
            icon: const Icon(LucideIcons.x, color: Colors.grey),
            tooltip: 'Deny Cancellation (Keep Approved)',
          ),
        ],
      );
    }

    return _buildStatusBadge(leave.status);
  }

  void _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String leaveId,
    LeaveStatus status,
  ) async {
    String actionLabel = 'process';
    if (status == LeaveStatus.approved) actionLabel = 'approve';
    if (status == LeaveStatus.rejected) actionLabel = 'reject';
    if (status == LeaveStatus.cancelled)
      actionLabel = 'confirm cancellation of';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('${status.name.toUpperCase()} Leave'),
        content: Text('Are you sure you want to $actionLabel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (status == LeaveStatus.approved ||
                      status == LeaveStatus.cancelled)
                  ? Colors.green
                  : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(leaveServiceProvider)
          .updateStatus(leaveId: leaveId, status: status);
    }
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    Color color;
    String label = status.name.toUpperCase();
    switch (status) {
      case LeaveStatus.approved:
        color = Colors.green;
        break;
      case LeaveStatus.rejected:
        color = Colors.red;
        break;
      case LeaveStatus.cancelled:
        color = Colors.grey;
        break;
      case LeaveStatus.cancel_requested:
        color = Colors.purple;
        label = 'CANCEL REQ';
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
