import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/session.dart';
import '/core/models/time_slot.dart';
import '/core/providers/office_settings_providers.dart';
import '/core/providers/session_providers.dart';
import 'widgets/office_closed_view.dart';
import 'widgets/session_table.dart';

class DailyView extends ConsumerWidget {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleViewProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final closedReasonAsync = ref.watch(isOfficeClosedProvider(selectedDate));

    return closedReasonAsync.when(
      data: (reason) {
        if (reason != null) return OfficeClosedView(reason: reason);

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
                      physics: const NeverScrollableScrollPhysics(),
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

                    //
                    // Content Area with Summary and Table
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: sortedSlots.map((slot) {
                          final sessions =
                              view.sessionsByTimeSlot[slot.id] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompactSummary(context, sessions),
                              Expanded(
                                child: SessionTable(
                                  sessions: sessions,
                                  slotId: slot.id,
                                ),
                              ),
                            ],
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

  Widget _buildCompactSummary(
    BuildContext context,
    List<SessionCardData> sessions,
  ) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    final total = sessions.length;
    final absences = sessions.where((s) => s.isClientAbsent).length;
    final leaves = sessions
        .where((s) => s.absentTherapistIds.isNotEmpty)
        .length;

    int regular = 0;
    int cover = 0;
    int makeup = 0;
    int extra = 0;

    for (var s in sessions) {
      final types = s.services.map((sv) => sv.sessionType).toSet();
      if (types.contains(SessionType.regular)) regular++;
      if (types.contains(SessionType.cover)) cover++;
      if (types.contains(SessionType.makeup)) makeup++;
      if (types.contains(SessionType.extra)) extra++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatChip('Total Sessions', total.toString(), Colors.blue),
                if (absences > 0)
                  _buildStatChip(
                    'Client Absence',
                    absences.toString(),
                    Colors.red,
                  ),
                if (leaves > 0)
                  _buildStatChip(
                    'Therapist Leave',
                    leaves.toString(),
                    Colors.orange,
                  ),
                const SizedBox(width: 4),
                _buildTypeBadge('Regular', regular, Colors.green),
                _buildTypeBadge('Cover', cover, Colors.orange),
                _buildTypeBadge('Makeup', makeup, Colors.teal),
                _buildTypeBadge('EXTRA', extra, Colors.purple),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              visualDensity: VisualDensity(vertical: -3),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(LucideIcons.filter, size: 14),
            label: const Text('Filter', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      height: 18,
      padding: .only(left: 3, right: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String label, int value, Color color) {
    return Container(
      height: 16,
      padding: .only(left: 3, right: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color.withOpacity(0.9),
            ),
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
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return time24h;
    }
  }
}
