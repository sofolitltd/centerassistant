import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/models/leave.dart';
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
}

class AdminApplyLeavePage extends ConsumerStatefulWidget {
  final String entityId;
  final String entityName;

  const AdminApplyLeavePage({
    super.key,
    required this.entityId,
    required this.entityName,
  });

  @override
  ConsumerState<AdminApplyLeavePage> createState() =>
      _AdminApplyLeavePageState();
}

class _AdminApplyLeavePageState extends ConsumerState<AdminApplyLeavePage> {
  final Map<DateTime, LeaveEntry> _entryMap = {};
  DateTime _focusedDay = DateTime.now();

  void _onDaySelected(
    DateTime selectedDay,
    DateTime focusedDay,
    List<Leave> existingLeaves,
  ) {
    setState(() => _focusedDay = focusedDay);
    final normalizedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    if (_entryMap.containsKey(normalizedDay)) {
      _showConfigurationDialog(
        normalizedDay,
        existingEntry: _entryMap[normalizedDay],
      );
      return;
    }

    final alreadyExists = existingLeaves.any(
      (l) =>
          l.date.year == normalizedDay.year &&
          l.date.month == normalizedDay.month &&
          l.date.day == normalizedDay.day &&
          (l.status == LeaveStatus.approved || l.status == LeaveStatus.pending),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unavailability already exists for ${DateFormat('MMM dd').format(normalizedDay)}',
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
                isEditing ? 'Edit Details' : 'Configure Entry',
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
                  _buildField(
                    'Entry Type',
                    ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButtonFormField<LeaveType>(
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
                        onChanged: (v) =>
                            setDialogState(() => selectedType = v!),
                        decoration: _inputDecoration(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'Duration',
                    ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButtonFormField<LeaveDuration>(
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
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'Admin Note',
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration(hint: 'Reason for entry...'),
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
                  setState(() => _entryMap.remove(date));
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),

            //
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () => _entryMap[date] = LeaveEntry(
                    date: date,
                    type: selectedType,
                    duration: selectedDuration,
                    reason: reasonController.text,
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingLeavesAsync = ref.watch(
      leavesByEntityProvider(widget.entityId),
    );
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1100;
    final sortedDates = _entryMap.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.black12.withValues(alpha: .03),
      body: existingLeavesAsync.when(
        data: (existingLeaves) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              Row(
                children: [
                  _breadcrumb('Admin', () => context.go('/admin/dashboard')),
                  _separator(),
                  _breadcrumb('Availability', () => context.pop()),
                  _separator(),
                  Text(
                    'Mark Entry: ${widget.entityName}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Mark Unavailability',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildCalendar(theme, existingLeaves),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildSummary(theme, sortedDates)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildCalendar(theme, existingLeaves),
                    const SizedBox(height: 24),
                    _buildSummary(theme, sortedDates),
                  ],
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme, List<Leave> existing) {
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
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _entryMap.containsKey(DateTime(day.year, day.month, day.day)),
              onDaySelected: (sel, foc) => _onDaySelected(sel, foc, existing),
              eventLoader: (day) => existing
                  .where(
                    (l) =>
                        isSameDay(l.date, day) &&
                        (l.status == LeaveStatus.approved ||
                            l.status == LeaveStatus.pending),
                  )
                  .toList(),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, List<DateTime> sortedDates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: Center(child: Text('Select dates from calendar.')),
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedDates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = _entryMap[sortedDates[index]]!;
              return _buildSummaryItem(theme, entry);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final service = ref.read(leaveServiceProvider);
                for (var entry in _entryMap.values) {
                  await service.addLeave(
                    employeeId: widget.entityId,
                    date: entry.date,
                    reason: entry.reason,
                    leaveType: entry.type,
                    duration: entry.duration,
                  );
                }
                if (mounted) context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text('Save ${sortedDates.length} Entry(ies)'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(ThemeData theme, LeaveEntry entry) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          DateFormat('MMM dd, yyyy').format(entry.date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${entry.type.name.toUpperCase()} • ${entry.duration.name.toUpperCase()} DAY',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.edit2, size: 16),
          onPressed: () =>
              _showConfigurationDialog(entry.date, existingEntry: entry),
        ),
      ),
    );
  }

  Widget _buildField(String label, Widget child) {
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

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _breadcrumb(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _separator() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
  );
}
