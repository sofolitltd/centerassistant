import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/session.dart';
import '/core/providers/session_providers.dart';
import 'delete_session_dialog.dart';
import 'status_update_dialog.dart';

class SessionTable extends ConsumerWidget {
  final List<SessionCardData> sessions;
  final String slotId;

  const SessionTable({super.key, required this.sessions, required this.slotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
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
                    8: FixedColumnWidth(150),
                    9: FixedColumnWidth(80),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: .05),
                      ),
                      children: [
                        _buildHeaderCell('#'),
                        _buildHeaderCell('Name(ID)'),
                        _buildHeaderCell('Therapist'),
                        _buildHeaderCell('Services'),
                        _buildHeaderCell('Hour'),
                        _buildHeaderCell('Duration'),
                        _buildHeaderCell('Inc/Exc'),
                        _buildHeaderCell('Type', align: TextAlign.center),
                        _buildHeaderCell(
                          'Session Status',
                          align: TextAlign.center,
                        ),
                        _buildHeaderCell('Action', align: TextAlign.center),
                      ],
                    ),

                    //
                    ...List.generate(sessions.length, (index) {
                      final s = sessions[index];
                      final bool isEven = index % 2 == 0;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: isEven
                              ? Colors.white
                              : Colors.blueGrey.shade50,
                        ),
                        children: [
                          _buildDataCell(
                            Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          _buildDataCell(
                            ConstrainedBox(
                              constraints: .new(
                                minWidth: constraints.maxWidth < 600
                                    ? 150
                                    : 200,
                              ),
                              child: Text(
                                s.displayFullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          _buildDataCell(
                            ConstrainedBox(
                              constraints: .new(
                                minWidth: constraints.maxWidth < 600
                                    ? 100
                                    : 150,
                              ),
                              child: _buildMultiServiceCell(s.therapists),
                            ),
                          ),
                          _buildDataCell(
                            Container(
                              constraints: .new(
                                minWidth: constraints.maxWidth < 600 ? 72 : 72,
                              ),
                              child: _buildMultiServiceCell(s.serviceNames),
                            ),
                          ),
                          _buildDataCell(
                            _buildMultiServiceCell(s.hours, formatTime: true),
                          ),
                          _buildDataCell(_buildMultiServiceCell(s.durations)),
                          _buildDataCell(
                            _buildMultiServiceCell(s.inclusiveStatus),
                          ),
                          _buildDataCell(_buildTypeBadge(s.typeDisplay)),

                          //
                          _buildDataCell(
                            _buildStatusBadge(context, ref, s, slotId),
                          ),

                          //
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
      onTap: () => showDialog(
        context: context,
        builder: (context) =>
            StatusUpdateDialog(session: session, timeSlotId: timeSlotId),
      ),
      child: Container(
        padding: const .fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: .spaceBetween,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
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

  void _handleDelete(
    BuildContext context,
    WidgetRef ref,
    SessionCardData session,
    String timeSlotId,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          DeleteSessionDialog(session: session, timeSlotId: timeSlotId),
    );
  }
}
