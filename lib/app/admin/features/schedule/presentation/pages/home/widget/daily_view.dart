import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;
import 'package:intl/intl.dart';

import '/core/providers/office_settings_providers.dart';
import '/core/providers/session_providers.dart';
import '../../../widgets/session_card.dart';
import '../schedule_planner_page.dart';

class DailyView extends ConsumerWidget {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleViewProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final closedReasonAsync = ref.watch(isOfficeClosedProvider(selectedDate));

    return scheduleAsync.when(
      data: (view) {
        if (view.timeSlots.isEmpty) {
          return const Center(child: Text('No time slots available'));
        }

        // Sort time slots by start time
        final sortedSlots = List<dynamic>.from(view.timeSlots)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: closedReasonAsync.when(
                data: (reason) {
                  if (reason != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            size: 64,
                            color: Colors.red.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Center Closed: $reason',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No sessions can be scheduled on this day.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(388),
                        border: TableBorder(
                          borderRadius: BorderRadius.circular(4),
                          verticalInside: BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          top: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          right: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          left: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          bottom: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                        ),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: headerBgColor,
                              border: Border(
                                bottom: BorderSide(
                                  color: gridBorderColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            children: sortedSlots.map((slot) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ' (${slot.label})',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final filter = ref.read(
                                        scheduleFilterProvider,
                                      );
                                      String path =
                                          '/admin/schedule/add?timeSlotId=${slot.id}';
                                      if (filter.clientId != null) {
                                        path += '&clientId=${filter.clientId}';
                                      }
                                      if (filter.employeeId != null) {
                                        path +=
                                            '&employeeId=${filter.employeeId}';
                                      }
                                      context.push(path);
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: Colors.black38,
                                    ),
                                    tooltip: 'Add Session',
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          TableRow(
                            children: sortedSlots.map((slot) {
                              final sessions =
                                  view.sessionsByTimeSlot[slot.id] ?? [];
                              return Container(
                                color: cellBgColor,
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (sessions.isEmpty)
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 400,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'No sessions scheduled',
                                            style: TextStyle(
                                              color: Colors.black26,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...sessions.map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: SessionCard(
                                            session: s,
                                            timeSlotId: slot.id,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),
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
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2024, 1, 1, hour, minute);
      return DateFormat.jm().format(dt);
    } catch (e) {
      return time24h;
    }
  }
}
