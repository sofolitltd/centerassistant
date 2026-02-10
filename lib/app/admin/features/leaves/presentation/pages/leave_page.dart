import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/models/leave.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';

class LeavePage extends ConsumerStatefulWidget {
  final String entityId;
  final String entityName;

  const LeavePage({
    super.key,
    required this.entityId,
    required this.entityName,
  });

  @override
  ConsumerState<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends ConsumerState<LeavePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  LeaveType _selectedType = LeaveType.annual;
  LeaveDuration _selectedDuration = LeaveDuration.full;
  final _reasonController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _rangeStart = start;
      _rangeEnd = end;
      _focusedDay = focusedDay;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leavesAsync = ref.watch(leavesByEntityProvider(widget.entityId));
    final employeeAsync = ref.watch(employeeByIdProvider(widget.entityId));
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leave Management',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildSummaryGrid(leavesAsync, employeeAsync, width),
            const SizedBox(height: 32),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildHistorySection(theme, leavesAsync),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 4,
                    child: _buildActionCard(theme, leavesAsync),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildActionCard(theme, leavesAsync),
                  const SizedBox(height: 32),
                  _buildHistorySection(theme, leavesAsync),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
    AsyncValue<List<Leave>> leavesAsync,
    AsyncValue<dynamic> employeeAsync,
    double width,
  ) {
    return leavesAsync.when(
      data: (leaves) {
        double calculateUsed(LeaveType type) {
          return leaves
              .where(
                (l) => l.leaveType == type && l.status == LeaveStatus.approved,
              )
              .fold(
                0.0,
                (sum, l) =>
                    sum + (l.duration == LeaveDuration.full ? 1.0 : 0.5),
              );
        }

        final annualUsed = calculateUsed(LeaveType.annual);
        final sickUsed = calculateUsed(LeaveType.sick);
        final causalUsed = calculateUsed(LeaveType.causal);

        final crossAxisCount = width > 1100 ? 4 : (width > 700 ? 2 : 1);

        String formatCount(double count) {
          return count == count.toInt().toDouble()
              ? count.toInt().toString()
              : count.toStringAsFixed(1);
        }

        return employeeAsync.when(
          data: (employee) {
            final carriedForward = (employee?.carriedForwardLeaves ?? 0);
            final totalAnnualAvailable = 18 + carriedForward;

            return MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              itemCount: 4,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryCard(
                    'Annual Leave',
                    '${formatCount(annualUsed)}/$totalAnnualAvailable',
                    carriedForward > 0
                        ? 'Includes $carriedForward carried forward'
                        : 'days remaining',
                    LucideIcons.userCheck,
                    const Color(0xFF1976D2),
                  );
                }
                if (index == 1) {
                  return _buildSummaryCard(
                    'Sick Leave',
                    '${formatCount(sickUsed)}/10',
                    'days remaining',
                    LucideIcons.stethoscope,
                    const Color(0xFFFFA000),
                  );
                }
                if (index == 2) {
                  return _buildSummaryCard(
                    'Causal Leave',
                    '${formatCount(causalUsed)}/5',
                    'days remaining',
                    LucideIcons.briefcase,
                    const Color(0xFF388E3C),
                  );
                }
                return _buildSummaryCard(
                  'Unpaid Leave',
                  'Available',
                  'When Needed',
                  LucideIcons.calendarX,
                  const Color(0xFFD32F2F),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    spacing: 4,
                    crossAxisAlignment: .baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "($subtitle)",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    ThemeData theme,
    AsyncValue<List<Leave>> leavesAsync,
  ) {
    return Container(
      padding: .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent History',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          leavesAsync.when(
            data: (leaves) {
              if (leaves.isEmpty) {
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No history found')),
                  ),
                );
              }

              final groupedLeaves = _groupConsecutiveLeaves(leaves);

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedLeaves.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final group = groupedLeaves[index];
                  return _buildHistoryGroupCard(group, theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  List<List<Leave>> _groupConsecutiveLeaves(List<Leave> leaves) {
    if (leaves.isEmpty) return [];

    final sorted = List<Leave>.from(leaves)
      ..sort((a, b) => a.date.compareTo(b.date));
    List<List<Leave>> grouped = [];
    if (sorted.isEmpty) return grouped;

    List<Leave> currentGroup = [sorted[0]];

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];

      final isConsecutive = curr.date.difference(prev.date).inDays == 1;
      final sameType = curr.leaveType == prev.leaveType;
      final sameStatus = curr.status == prev.status;
      final sameReason = curr.reason == prev.reason;
      final sameDuration = curr.duration == prev.duration;

      if (isConsecutive &&
          sameType &&
          sameStatus &&
          sameReason &&
          sameDuration) {
        currentGroup.add(curr);
      } else {
        grouped.add(currentGroup);
        currentGroup = [curr];
      }
    }
    grouped.add(currentGroup);

    // Sort groups descending by start date
    grouped.sort((a, b) => b[0].date.compareTo(a[0].date));
    return grouped;
  }

  Widget _buildHistoryGroupCard(List<Leave> group, ThemeData theme) {
    final first = group.first;
    final last = group.last;
    final isRange = group.length > 1;

    String dateText;
    if (isRange) {
      dateText =
          '${DateFormat('MMM dd').format(first.date)} - ${DateFormat('MMM dd, yyyy').format(last.date)}';
    } else {
      dateText = DateFormat('MMMM dd, yyyy').format(first.date);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getLeaveColor(
            first.leaveType,
          ).withValues(alpha: 0.1),
          child: Icon(
            LucideIcons.calendar,
            size: 18,
            color: _getLeaveColor(first.leaveType),
          ),
        ),
        title: Text(
          dateText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${first.leaveType.name.toUpperCase()} • ${first.duration.name.toUpperCase()} DAY${isRange ? 'S' : ''} (${group.length})',
            ),
            if (first.reason != null && first.reason!.isNotEmpty)
              Text(
                first.reason!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBadge(first.status),
            const SizedBox(width: 8),
            if (first.status == LeaveStatus.pending ||
                first.status == LeaveStatus.cancelRequest)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        _updateGroupStatus(group, LeaveStatus.approved),
                    icon: const Icon(
                      LucideIcons.checkCircle,
                      color: Colors.green,
                    ),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    onPressed: () =>
                        _updateGroupStatus(group, LeaveStatus.rejected),
                    icon: const Icon(LucideIcons.xCircle, color: Colors.red),
                    tooltip: 'Reject',
                  ),
                ],
              )
            else if (first.status == LeaveStatus.approved)
              IconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => _showConfirmDialog(
                  context,
                  'Delete Entry',
                  'Are you sure you want to remove this ${isRange ? 'range' : 'entry'}?',
                  () => _deleteGroup(group),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateGroupStatus(List<Leave> group, LeaveStatus status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('${status.name.toUpperCase()} Request'),
        content: Text(
          'Are you sure you want to ${status.name} this ${group.length > 1 ? 'range' : 'entry'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == LeaveStatus.approved
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
      final service = ref.read(leaveServiceProvider);
      for (var leave in group) {
        await service.updateStatus(leaveId: leave.id, status: status);
      }
    }
  }

  Future<void> _deleteGroup(List<Leave> group) async {
    final service = ref.read(leaveServiceProvider);
    for (var leave in group) {
      await service.removeLeave(leave.id);
    }
  }

  Widget _buildActionCard(
    ThemeData theme,
    AsyncValue<List<Leave>> existingLeavesAsync,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Leave',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            existingLeavesAsync.when(
              data: (existing) => TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: _rangeSelectionMode,
                onDaySelected: (sel, foc) => _onDaySelected(sel, foc),
                onRangeSelected: _onRangeSelected,
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
                  rangeStartDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: theme.colorScheme.primary.withOpacity(
                    0.1,
                  ),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            if (_selectedDay != null || _rangeStart != null) ...[
              _buildField(
                'Leave Type',
                DropdownButtonFormField<LeaveType>(
                  value: _selectedType,
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
                  onChanged: (v) => setState(() => _selectedType = v!),
                  decoration: _inputDecoration(),
                ),
              ),
              const SizedBox(height: 16),
              if (_rangeStart == null || _rangeEnd == null)
                _buildField(
                  'Duration',
                  DropdownButtonFormField<LeaveDuration>(
                    value: _selectedDuration,
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
                    onChanged: (v) => setState(() => _selectedDuration = v!),
                    decoration: _inputDecoration(),
                  ),
                ),
              const SizedBox(height: 16),
              _buildField(
                'Admin Note (Optional)',
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration(hint: 'Reason for leave...'),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Mark Leave'),
                ),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Select date or range to configure',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
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

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(leaveServiceProvider);

      List<DateTime> datesToProcess = [];
      if (_rangeStart != null && _rangeEnd != null) {
        DateTime current = _rangeStart!;
        while (current.isBefore(_rangeEnd!) || isSameDay(current, _rangeEnd!)) {
          datesToProcess.add(current);
          current = current.add(const Duration(days: 1));
        }
      } else if (_rangeStart != null) {
        datesToProcess.add(_rangeStart!);
      } else if (_selectedDay != null) {
        datesToProcess.add(_selectedDay!);
      }

      for (var date in datesToProcess) {
        await service.addLeave(
          employeeId: widget.entityId,
          date: date,
          reason: _reasonController.text.trim(),
          leaveType: _selectedType,
          duration: datesToProcess.length > 1
              ? LeaveDuration.full
              : _selectedDuration,
        );
      }

      if (mounted) {
        setState(() {
          _selectedDay = null;
          _rangeStart = null;
          _rangeEnd = null;
          _reasonController.clear();
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave(s) marked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
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
      case LeaveStatus.pending:
        color = Colors.orange;
        break;
      case LeaveStatus.cancelled:
        color = Colors.grey;
        break;
      case LeaveStatus.cancelRequest:
        color = Colors.purple;
        label = 'CANCEL REQ';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
}
