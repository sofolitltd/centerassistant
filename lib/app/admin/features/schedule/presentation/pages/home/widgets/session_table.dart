import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/session.dart';
import '/core/providers/session_providers.dart';
import 'delete_session_dialog.dart';
import 'status_update_dialog.dart';
import 'type_update_dialog.dart';

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
                        color: Colors.green.withOpacity(0.05),
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

                      final bool hasAbsence =
                          s.isClientAbsent || s.absentTherapistIds.isNotEmpty;

                      return TableRow(
                        decoration: BoxDecoration(
                          color: hasAbsence
                              ? Colors.orange.withOpacity(
                                  0.1,
                                ) // Alert color for absences
                              : (isEven
                                    ? Colors.white
                                    : Colors.blueGrey.shade50),
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
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth < 600
                                    ? 150
                                    : 200,
                              ),
                              child: InkWell(
                                onTap: () => context.push(
                                  '/admin/clients/${s.clientDocId}',
                                ),

                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          s.clientNickName ?? s.clientName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (s.isClientAbsent) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          height: 15,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          child: const Text(
                                            'Absent',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              height: 1,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildDataCell(
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth < 600
                                    ? 100
                                    : 150,
                              ),
                              child: _buildTherapistCell(s),
                            ),
                          ),
                          _buildDataCell(
                            Container(
                              constraints: BoxConstraints(
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

                          // Type
                          _buildDataCell(
                            _buildTypeBadge(context, ref, s, slotId),
                          ),

                          // Status
                          _buildDataCell(
                            _buildStatusBadge(context, ref, s, slotId),
                          ),

                          //
                          _buildDataCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => context.push(
                                    '/admin/schedule/${s.id}/edit',
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  constraints: const BoxConstraints(),
                                  splashRadius: 32,
                                ),
                                const SizedBox(width: 8),
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

  Widget _buildTherapistCell(SessionCardData s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: s.services.asMap().entries.map((entry) {
        final i = entry.key;
        final sv = entry.value;
        final name = s.employeeNames[sv.employeeId] ?? '-';
        final isAbsent = s.absentTherapistIds.contains(sv.employeeId);

        return Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: i < s.services.length - 1
                ? Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                  )
                : null,
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAbsent) ...[
                const SizedBox(width: 4),
                Container(
                  height: 15,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'Leave',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
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
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentStatus.displayName,
              style: TextStyle(
                color: color,
                fontSize: 10,
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

  Widget _buildTypeBadge(
    BuildContext context,
    WidgetRef ref,
    SessionCardData s,
    String timeSlotId,
  ) {
    final type = s.typeDisplay;
    Color color;
    switch (type.toLowerCase()) {
      case 'regular':
        color = Colors.green;
        break;
      case 'cover':
        color = Colors.orange;
        break;
      case 'makeup':
        color = Colors.teal;
        break;
      case 'extra':
        color = Colors.purpleAccent;
        break;
      default:
        color = Colors.blue;
    }
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (context) =>
            TypeUpdateDialog(session: s, timeSlotId: timeSlotId),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type[0].toUpperCase() + type.substring(1),
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
