import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
                    const Divider(height: 1),

                    //
                    Expanded(
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        children: sortedSlots.map((slot) {
                          return SessionTable(
                            sessions: view.sessionsByTimeSlot[slot.id] ?? [],
                            slotId: slot.id,
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
}
