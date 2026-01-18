import 'dart:ui' show PointerDeviceKind;

import 'package:center_assistant/core/models/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/time_slot.dart';
import '/core/providers/office_settings_providers.dart';
import '/core/providers/session_providers.dart';

class DailyView extends ConsumerWidget {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleViewProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final closedReasonAsync = ref.watch(isOfficeClosedProvider(selectedDate));

    return closedReasonAsync.when(
      data: (reason) {
        if (reason != null) return _buildClosedView(reason);

        return scheduleAsync.when(
          data: (view) {
            if (view.timeSlots.isEmpty) {
              return const Center(child: Text('No time slots available'));
            }

            final sortedSlots = List<TimeSlot>.from(view.timeSlots)
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

            return DefaultTabController(
              length: sortedSlots.length,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      padding: EdgeInsets.zero,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 13),
                      tabs: sortedSlots.map((slot) {
                        return Tab(
                          height: 40,
                          text:
                              "${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}",
                        );
                      }).toList(),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: sortedSlots.map((slot) {
                          return _buildSessionTable(
                            context,
                            ref,
                            view,
                            slot.id,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSessionTable(
    BuildContext context,
    WidgetRef ref,
    ScheduleView view,
    String slotId,
  ) {
    final sessions = view.sessionsByTimeSlot[slotId] ?? [];

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            const Text(
              'No sessions scheduled',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 600,
                  maxWidth: (constraints.maxWidth > 1000)
                      ? 1000
                      : constraints.maxWidth.clamp(600.0, double.infinity),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                    columnWidths: const {
                      0: FixedColumnWidth(40),
                      1: IntrinsicColumnWidth(),
                      2: IntrinsicColumnWidth(),
                      3: IntrinsicColumnWidth(),
                      4: FixedColumnWidth(140),
                      5: FixedColumnWidth(80),
                      6: FixedColumnWidth(80),
                      7: FixedColumnWidth(100),
                      8: IntrinsicColumnWidth(),
                      9: FixedColumnWidth(80),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: [
                          _buildHeaderCell('#'),
                          _buildHeaderCell('Name(ID)'),
                          _buildHeaderCell('Therapist'),
                          _buildHeaderCell('Services'),
                          _buildHeaderCell('Hour'),
                          _buildHeaderCell('Duration'),
                          _buildHeaderCell('Inc/Exc'),
                          _buildHeaderCell('Type'),
                          _buildHeaderCell('Status'),
                          _buildHeaderCell('Action', align: TextAlign.center),
                        ],
                      ),
                      ...List.generate(sessions.length, (index) {
                        final s = sessions[index];
                        final bool isEven = index % 2 == 0;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white : Colors.grey.shade50,
                          ),
                          children: [
                            _buildDataCell(
                              Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            _buildDataCell(
                              Text(
                                s.displayFullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            _buildDataCell(
                              _buildMultiServiceCell(s.therapists),
                            ),
                            _buildDataCell(
                              _buildMultiServiceCell(s.serviceNames),
                            ),
                            _buildDataCell(
                              _buildMultiServiceCell(s.hours, formatTime: true),
                            ),
                            _buildDataCell(_buildMultiServiceCell(s.durations)),
                            _buildDataCell(
                              _buildMultiServiceCell(s.inclusiveStatus),
                            ),
                            _buildDataCell(_buildTypeBadge(s.typeDisplay)),
                            _buildDataCell(
                              _buildStatusBadge(context, ref, s, slotId),
                            ),
                            _buildDataCell(
                              Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => context.push(
                                      '/admin/schedule/edit/${s.id}',
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 32,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () =>
                                        _handleDelete(context, ref, s, slotId),
                                    padding: const EdgeInsets.all(2),
                                    constraints: const BoxConstraints(),
                                    splashRadius: 32,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }

  Widget _buildMultiServiceCell(String text, {bool formatTime = false}) {
    final lines = text.split('\n');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (i) {
        return Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: i < lines.length - 1
                ? Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                  )
                : null,
          ),
          child: Text(
            formatTime ? _formatTimeRange(lines[i]) : lines[i],
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );
  }

  String _formatTimeRange(String range) {
    if (!range.contains('-')) return range;
    final parts = range.split('-');
    if (parts.length != 2) return range;
    return "${_formatTime(parts[0])} - ${_formatTime(parts[1])}";
  }

  Widget _buildStatusBadge(
    BuildContext context,
    WidgetRef ref,
    SessionCardData session,
    String timeSlotId,
  ) {
    final currentStatus = session.status;
    Color color;
    switch (currentStatus) {
      case SessionStatus.completed:
        color = Colors.green;
        break;
      case SessionStatus.cancelledCenter:
      case SessionStatus.cancelledClient:
        color = Colors.red;
        break;
      case SessionStatus.pending:
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return InkWell(
      onTap: () => _showStatusUpdateDialog(context, ref, session, timeSlotId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentStatus.displayName,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    SessionCardData session,
    String timeSlotId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return _StatusUpdateDialog(session: session, timeSlotId: timeSlotId);
      },
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    switch (type.toLowerCase()) {
      case 'regular':
        color = Colors.green;
        break;
      case 'cover':
        color = Colors.orange;
      case 'makeup':
        color = Colors.teal;
      case 'extra':
        color = Colors.purpleAccent;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildClosedView(String reason) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 60, color: Colors.orange.shade200),
          const SizedBox(height: 12),
          Text(
            'Office Closed: $reason',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Scheduling is disabled for this date.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time24h) {
    if (time24h.isEmpty) return '';
    try {
      final parts = time24h.split(':');
      if (parts.length < 2) return time24h;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2024, 1, 1, hour, minute);
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return time24h;
    }
  }

  void _handleDelete(
    BuildContext context,
    WidgetRef ref,
    SessionCardData session,
    String timeSlotId,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          _DeleteSessionDialog(session: session, timeSlotId: timeSlotId),
    );
  }
}

class _StatusUpdateDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;

  const _StatusUpdateDialog({required this.session, required this.timeSlotId});

  @override
  ConsumerState<_StatusUpdateDialog> createState() =>
      _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends ConsumerState<_StatusUpdateDialog> {
  late SessionStatus _selectedStatus;
  String _mode = 'this_only';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.session.status;
  }

  bool get _canConfirm =>
      _selectedStatus != widget.session.status || _mode != 'this_only';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Update Session Status', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Status',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SessionStatus>(
              value: _selectedStatus,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: SessionStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Apply to',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text(
                'This session only',
                style: TextStyle(fontSize: 14),
              ),
              value: 'this_only',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
            RadioListTile<String>(
              title: const Text(
                'This and following',
                style: TextStyle(fontSize: 14),
              ),
              value: 'this_and_following',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
            RadioListTile<String>(
              title: const Text('All sessions', style: TextStyle(fontSize: 14)),
              value: 'all',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || !_canConfirm) ? null : _handleUpdate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      final selectedDate = ref.read(selectedDateProvider);
      await ref
          .read(sessionServiceProvider)
          .updateSessionStatus(
            clientId: widget.session.clientDocId,
            timeSlotId: widget.timeSlotId,
            services: widget.session.services,
            newStatus: _selectedStatus,
            date: selectedDate,
            mode: _mode,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _DeleteSessionDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;

  const _DeleteSessionDialog({required this.session, required this.timeSlotId});

  @override
  ConsumerState<_DeleteSessionDialog> createState() =>
      _DeleteSessionDialogState();
}

class _DeleteSessionDialogState extends ConsumerState<_DeleteSessionDialog> {
  String _mode = 'this_only';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Delete Session', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Which sessions would you like to permanently delete?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apply to',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text(
                'This session only',
                style: TextStyle(fontSize: 14),
              ),
              value: 'this_only',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
            RadioListTile<String>(
              title: const Text(
                'This and following',
                style: TextStyle(fontSize: 14),
              ),
              value: 'this_and_following',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
            RadioListTile<String>(
              title: const Text('All sessions', style: TextStyle(fontSize: 14)),
              value: 'all',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => _HardDeleteConfirmDialog(
                      session: widget.session,
                      timeSlotId: widget.timeSlotId,
                      mode: _mode,
                    ),
                  );
                },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _HardDeleteConfirmDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;
  final String mode;

  const _HardDeleteConfirmDialog({
    required this.session,
    required this.timeSlotId,
    required this.mode,
  });

  @override
  ConsumerState<_HardDeleteConfirmDialog> createState() =>
      _HardDeleteConfirmDialogState();
}

class _HardDeleteConfirmDialogState
    extends ConsumerState<_HardDeleteConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    String modeText = '';
    switch (widget.mode) {
      case 'this_only':
        modeText = 'this specific session';
        break;
      case 'this_and_following':
        modeText = 'this and all following sessions';
        break;
      case 'all':
        modeText = 'ALL sessions and the template rule';
        break;
    }

    return AlertDialog(
      title: const Text('Confirm Permanent Deletion'),
      constraints: BoxConstraints(maxWidth: 400),
      content: Text(
        'Are you sure you want to permanently delete $modeText? '
        'This will clean up Firestore and cannot be undone. '
        '${widget.mode == 'all' ? '\n\nWARNING: This will also remove the recurring rule from the schedule template.' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _handleHardDelete,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete Forever'),
        ),
      ],
    );
  }

  Future<void> _handleHardDelete() async {
    setState(() => _isLoading = true);
    try {
      final selectedDate = ref.read(selectedDateProvider);
      await ref
          .read(sessionServiceProvider)
          .hardDeleteSession(
            clientId: widget.session.clientDocId,
            timeSlotId: widget.timeSlotId,
            date: selectedDate,
            mode: widget.mode,
          );
      if (mounted) {
        // Pop the confirmation dialog
        Navigator.pop(context);
        // Pop the delete options dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permanently deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
