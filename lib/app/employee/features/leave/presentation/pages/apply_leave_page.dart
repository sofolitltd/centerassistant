import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/models/leave.dart';
import '/core/providers/auth_providers.dart';
import '/core/providers/leave_providers.dart';

class LeaveEntry {
  final DateTime date;
  LeaveDuration duration;
  LeaveType type;
  String reason;

  LeaveEntry({
    required this.date,
    this.duration = LeaveDuration.full,
    this.type = LeaveType.annual,
    this.reason = '',
  });

  LeaveEntry copyWith({
    LeaveDuration? duration,
    LeaveType? type,
    String? reason,
  }) {
    return LeaveEntry(
      date: date,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      reason: reason ?? this.reason,
    );
  }
}

class ApplyLeavePage extends ConsumerStatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  ConsumerState<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends ConsumerState<ApplyLeavePage> {
  final Map<DateTime, LeaveEntry> _entryMap = {};
  DateTime _focusedDay = DateTime.now();

  void _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
    List<Leave> existingLeaves,
  ) {
    setState(() {
      _focusedDay = focusedDay;
    });
    final normalizedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    // 1. Check if date is in the current batch
    if (_entryMap.containsKey(normalizedDay)) {
      _showConfigurationDialog(
        normalizedDay,
        existingEntry: _entryMap[normalizedDay],
      );
      return;
    }

    // 2. Check if date already exists in DB (Pending or Approved)
    final existing = existingLeaves.any(
      (l) =>
          l.date.year == normalizedDay.year &&
          l.date.month == normalizedDay.month &&
          l.date.day == normalizedDay.day &&
          (l.status == LeaveStatus.approved || l.status == LeaveStatus.pending),
    );

    if (existing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave already pending or approved for ${DateFormat('MMM dd').format(normalizedDay)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showConfigurationDialog(normalizedDay);
  }

  Future<void> _showConfigurationDialog(
    DateTime date, {
    LeaveEntry? existingEntry,
  }) async {
    final theme = Theme.of(context);
    final isEditing = existingEntry != null;

    LeaveType selectedType = existingEntry?.type ?? LeaveType.annual;
    LeaveDuration selectedDuration =
        existingEntry?.duration ?? LeaveDuration.full;
    final reasonController = TextEditingController(
      text: existingEntry?.reason ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? 'Edit Leave Details' : 'Configure Leave',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(minWidth: 350, maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(date),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDialogField(
                    'Leave Type',
                    DropdownButtonFormField<LeaveType>(
                      value: selectedType,
                      isDense: true,
                      items: LeaveType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.name.toUpperCase(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                      decoration: _inputDecoration(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogField(
                    'Duration',
                    DropdownButtonFormField<LeaveDuration>(
                      value: selectedDuration,
                      items: LeaveDuration.values
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                '${d.name} day'.toUpperCase(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedDuration = v!),
                      decoration: _inputDecoration(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogField(
                    'Notes (Optional)',
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration(hint: 'Reason for leave...'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _entryMap.remove(date);
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _entryMap[date] = LeaveEntry(
                    date: date,
                    type: selectedType,
                    duration: selectedDuration,
                    reason: reasonController.text,
                  );
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Add to List'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final employeeId = authState.employeeId;

    if (employeeId == null) return const SizedBox();

    final existingLeavesAsync = ref.watch(leavesByEntityProvider(employeeId));
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1100;

    final sortedDates = _entryMap.keys.toList()..sort();

    return Scaffold(
      body: existingLeavesAsync.when(
        data: (existingLeaves) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                  InkWell(
                    onTap: () => context.go('/employee/leave'),
                    child: Text(
                      'Leave Management',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  Text('Apply Leave', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'New Leave Application',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isDesktop ? 2 : 5,
                    child: _buildCalendarSection(
                      theme,
                      sortedDates,
                      existingLeaves,
                    ),
                  ),
                  if (isDesktop) const SizedBox(width: 24),
                  if (isDesktop)
                    Expanded(
                      flex: 3,
                      child: _buildSummarySection(
                        theme,
                        sortedDates,
                        employeeId,
                      ),
                    ),
                ],
              ),
              if (!isDesktop) ...[
                const SizedBox(height: 24),
                _buildSummarySection(theme, sortedDates, employeeId),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCalendarSection(
    ThemeData theme,
    List<DateTime> sortedDates,
    List<Leave> existingLeaves,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Select Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) =>
                  _entryMap.containsKey(DateTime(day.year, day.month, day.day)),
              onDaySelected: (sel, foc) =>
                  _onDaySelected(sel, foc, existingLeaves),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              eventLoader: (day) {
                return existingLeaves
                    .where(
                      (l) =>
                          l.date.year == day.year &&
                          l.date.month == day.month &&
                          l.date.day == day.day &&
                          (l.status == LeaveStatus.approved ||
                              l.status == LeaveStatus.pending),
                    )
                    .toList();
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: theme.colorScheme.primary),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: Tap a date to configure leave details. Small dots indicate already pending or approved leaves.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    ThemeData theme,
    List<DateTime> sortedDates,
    String employeeId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Review Applications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_entryMap.isEmpty)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(60),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.calendar, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No dates selected yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedDates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final entry = _entryMap[date]!;
              return _buildSummaryItem(entry, theme);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _submitAll(employeeId),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit ${sortedDates.length} Application(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(LeaveEntry entry, ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _getLeaveColor(entry.type).withValues(alpha: 0.1),
          child: Icon(
            LucideIcons.calendar,
            size: 18,
            color: _getLeaveColor(entry.type),
          ),
        ),
        title: Text(
          DateFormat('MMM dd, yyyy').format(entry.date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${entry.type.name.toUpperCase()} • ${entry.duration.name.toUpperCase()} DAY',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.white,
          icon: const Icon(
            LucideIcons.moreVertical,
            size: 18,
            color: Colors.grey,
          ),
          onSelected: (value) {
            if (value == 'edit') {
              _showConfigurationDialog(entry.date, existingEntry: entry);
            } else if (value == 'delete') {
              setState(() {
                _entryMap.remove(entry.date);
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              height: 35,
              child: Row(
                children: [
                  Icon(LucideIcons.edit2, size: 14),
                  SizedBox(width: 8),
                  const Text('Edit', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              height: 35,
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                  SizedBox(width: 8),
                  const Text(
                    'Delete',
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
  }

  Color _getLeaveColor(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return Colors.blue;
      case LeaveType.sick:
        return Colors.orange;
      case LeaveType.causal:
        return Colors.green;
      case LeaveType.unpaid:
        return Colors.red;
    }
  }

  Future<void> _submitAll(String employeeId) async {
    final service = ref.read(leaveServiceProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Processing applications...')));

    try {
      for (final entry in _entryMap.values) {
        await service.addLeave(
          employeeId: employeeId,
          date: entry.date,
          reason: entry.reason,
          leaveType: entry.type,
          duration: entry.duration,
        );
      }
      if (mounted) {
        context.go('/employee/leave');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leaves applied successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
