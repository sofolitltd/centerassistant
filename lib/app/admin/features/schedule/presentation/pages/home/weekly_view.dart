import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/providers/office_settings_providers.dart';
import '/core/providers/session_providers.dart';
import '/core/providers/time_slot_providers.dart';
import 'schedule_planner_page.dart'
    show
        gridBorderColor,
        headerBgColor,
        cellBgColor,
        plannerViewNotifierProvider,
        PlannerView;
import 'widgets/compact_card.dart';

class WeeklyView extends ConsumerWidget {
  const WeeklyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final settingsAsync = ref.watch(officeSettingsProvider);

    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final weekDays = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );

    return timeSlotsAsync.when(
      data: (slots) {
        if (slots.isEmpty) {
          return const Center(child: Text('No time slots available'));
        }
        return settingsAsync.when(
          data: (settings) {
            final columnWidths = <int, TableColumnWidth>{
              0: const FixedColumnWidth(80),
            };
            for (int i = 0; i < 7; i++) {
              final dayName = DateFormat('EEEE').format(weekDays[i]);
              final isWeekend = settings.weeklyOffDays.contains(dayName);
              columnWidths[i + 1] = FlexColumnWidth(isWeekend ? 0.3 : 1.0);
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: columnWidths,
                  border: const TableBorder(
                    verticalInside: BorderSide(
                      color: gridBorderColor,
                      width: 1,
                    ),
                    horizontalInside: BorderSide(
                      color: gridBorderColor,
                      width: 1,
                    ),
                    top: BorderSide(color: gridBorderColor, width: 1),
                    right: BorderSide(color: gridBorderColor, width: 1),
                    left: BorderSide(color: gridBorderColor, width: 1),
                    bottom: BorderSide(color: gridBorderColor, width: 1),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: headerBgColor),
                      children: [
                        const SizedBox.shrink(),
                        ...weekDays.map((day) {
                          final isToday = isSameDay(day, DateTime.now());
                          final dayName = DateFormat('EEEE').format(day);
                          final isWeekend = settings.weeklyOffDays.contains(
                            dayName,
                          );

                          return InkWell(
                            onTap: () {
                              ref
                                  .read(selectedDateProvider.notifier)
                                  .setDate(day);
                              ref
                                  .read(plannerViewNotifierProvider.notifier)
                                  .setView(PlannerView.daily);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: isWeekend ? Colors.grey.shade50 : null,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(day).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isToday
                                          ? Colors.blue.shade700
                                          : (isWeekend
                                                ? Colors.red.shade300
                                                : Colors.black54),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? Colors.blue.shade700
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      DateFormat('dd').format(day),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isToday
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    ...slots.map((slot) {
                      return TableRow(
                        children: [
                          Container(
                            height: 150,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot.startTime,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "to",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black26,
                                  ),
                                ),
                                Text(
                                  slot.endTime,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...weekDays.map(
                            (day) => _WeeklyDayCell(
                              day: day,
                              slotId: slot.id,
                              isWeekend: settings.weeklyOffDays.contains(
                                DateFormat('EEEE').format(day),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
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
}

class _WeeklyDayCell extends ConsumerWidget {
  final DateTime day;
  final String slotId;
  final bool isWeekend;

  const _WeeklyDayCell({
    required this.day,
    required this.slotId,
    required this.isWeekend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleByDateProvider(day));
    final closedReasonAsync = ref.watch(isOfficeClosedProvider(day));

    return InkWell(
      onTap: () {
        ref.read(selectedDateProvider.notifier).setDate(day);
        ref
            .read(plannerViewNotifierProvider.notifier)
            .setView(PlannerView.daily);
      },
      child: closedReasonAsync.when(
        data: (reason) {
          if (reason != null) {
            Widget textWidget = Text(
              reason.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.red.withOpacity(0.3),
                letterSpacing: 1,
              ),
            );

            if (isWeekend) {
              textWidget = RotatedBox(quarterTurns: 3, child: textWidget);
            }

            return Container(
              height: 150,
              color: Colors.red.withOpacity(0.02),
              child: Center(child: textWidget),
            );
          }

          return Container(
            height: 150,
            padding: const EdgeInsets.all(4),
            color: cellBgColor,
            child: scheduleAsync.when(
              data: (view) {
                final sessions = view.sessionsByTimeSlot[slotId] ?? [];
                if (sessions.isEmpty) return const SizedBox.shrink();

                return Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    ...sessions.take(10).map((s) => CompactCard(session: s)),
                    if (sessions.length > 10)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Text(
                          '+${sessions.length - 10}',
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
