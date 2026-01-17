import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/session.dart';
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

            // Sort time slots
            final sortedSlots = List<dynamic>.from(view.timeSlots)
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

            return DefaultTabController(
              length: sortedSlots.length,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // --- DEFAULT TAB BAR ---
                    TabBar(
                      isScrollable: true,
                      physics: NeverScrollableScrollPhysics(),
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

                    // --- TAB BAR VIEW ---
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
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
    dynamic view,
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
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 600,
                maxWidth: constraints.maxWidth.clamp(600.0, 1200.0),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Table(
                          border: .all(color: Colors.grey, width: .5),
                          columnWidths: const {
                            0: FixedColumnWidth(32), // #
                            1: IntrinsicColumnWidth(), // Name(ID)
                            2: IntrinsicColumnWidth(), // Therapist
                            3: IntrinsicColumnWidth(), // Services
                            4: FixedColumnWidth(150), // Hour
                            5: FixedColumnWidth(80), // Dur.
                            6: FixedColumnWidth(100), // Inc/Exc
                            7: FixedColumnWidth(100), // Type
                            8: FixedColumnWidth(100), // Status
                            9: FixedColumnWidth(100), // Action
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            // --- HEADER ROW ---
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              children: [
                                _buildHeaderCell('#'),
                                Container(
                                  constraints: BoxConstraints(minWidth: 250),

                                  child: _buildHeaderCell('Name(ID)'),
                                ),
                                Container(
                                  constraints: BoxConstraints(minWidth: 150),
                                  child: _buildHeaderCell('Therapist'),
                                ),
                                Container(
                                  constraints: BoxConstraints(minWidth: 100),

                                  child: _buildHeaderCell('Services'),
                                ),
                                _buildHeaderCell('Hour'),
                                _buildHeaderCell('Dur.'),
                                _buildHeaderCell('Inc/Exc'),
                                _buildHeaderCell('Type'),
                                _buildHeaderCell('Status'),
                                _buildHeaderCell(
                                  'Action',
                                  align: TextAlign.center,
                                ),
                              ],
                            ),
                            // --- DATA ROWS ---
                            ...List.generate(sessions.length, (index) {
                              final s = sessions[index];
                              final bool isEven = index % 2 == 0;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? Colors.white
                                      : Colors.grey.shade50,
                                ),
                                children: [
                                  _buildDataCell(
                                    Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  _buildDataCell(
                                    Padding(
                                      padding: const .symmetric(
                                        horizontal: 8.0,
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
                                    _buildMultiServiceCell(s.therapists),
                                  ),
                                  _buildDataCell(
                                    _buildMultiServiceCell(s.serviceNames),
                                  ),
                                  _buildDataCell(
                                    _buildMultiServiceCell(
                                      s.hours,
                                      formatTime: true,
                                    ),
                                  ),
                                  _buildDataCell(
                                    _buildMultiServiceCell(s.durations),
                                  ),
                                  _buildDataCell(
                                    _buildMultiServiceCell(s.inclusiveStatus),
                                  ),
                                  _buildDataCell(
                                    Padding(
                                      padding: const .symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Container(
                                        padding: const .symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _getSessionCategory(s.sessionType),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildDataCell(
                                    _buildStatusBadge(
                                      _getSessionStatus(s.sessionType),
                                    ),
                                  ),
                                  _buildDataCell(
                                    Row(
                                      mainAxisAlignment: .center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          onPressed: () => context.push(
                                            '/admin/schedule/edit/${s.id}',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _handleDelete(s.id),
                                          visualDensity: VisualDensity.compact,
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
                ? Border(bottom: BorderSide(color: Colors.grey, width: 0.5))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              formatTime ? _formatTimeRange(lines[i]) : lines[i],
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
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

  String _getSessionCategory(SessionType type) {
    switch (type) {
      case SessionType.regular:
        return 'Regular';
      case SessionType.cover:
        return 'Cover';
      case SessionType.makeup:
        return 'Makeup';
      case SessionType.extra:
        return 'Extra';
      default:
        return 'Regular';
    }
  }

  String _getSessionStatus(SessionType type) {
    switch (type) {
      case SessionType.completed:
        return 'Complete';
      case SessionType.cancelled:
      case SessionType.cancelledCenter:
      case SessionType.cancelledClient:
        return 'Cancel';
      default:
        return 'Scheduled';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'complete':
        color = Colors.green;
        break;
      case 'cancel':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }
    return Padding(
      padding: const .symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Text(
          status,
          textAlign: .center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
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
      final dt = DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return time24h;
    }
  }

  void _handleDelete(String id) {}
}
