import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart' show isSameDay;

import '/core/providers/office_settings_providers.dart';
import '/core/providers/session_providers.dart';
import 'schedule_all_page.dart' show plannerViewNotifierProvider, PlannerView;
import 'schedule_utils.dart';
import 'widgets/compact_card.dart';

class MonthlyView extends ConsumerWidget {
  const MonthlyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final settingsAsync = ref.watch(officeSettingsProvider);

    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final gridStart = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));
    final weeks = List.generate(6, (i) => days.sublist(i * 7, (i + 1) * 7))
        .where((week) => week.any((day) => day.month == selectedDate.month))
        .toList();
    final weekLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return settingsAsync.when(
      data: (settings) {
        final columnWidths = <int, TableColumnWidth>{};
        for (int i = 0; i < 7; i++) {
          final fullDayName = DateFormat(
            'EEEE',
          ).format(DateTime(2024, 1, 7 + i)); // 2024-01-07 is Sunday
          final isWeekend = settings.weeklyOffDays.contains(fullDayName);
          columnWidths[i] = FlexColumnWidth(isWeekend ? 0.3 : 1.0);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate height per row to fill the available space
            const double headerHeight = 48.0;
            final double availableHeight =
                constraints.maxHeight - 32; // Vertical padding (16 * 2)
            final double rowHeight =
                (availableHeight - headerHeight) / weeks.length;

            return Container(
              padding: const EdgeInsets.all(16),
              child: Table(
                columnWidths: columnWidths,
                border: const TableBorder(
                  verticalInside: BorderSide(
                    color: ScheduleStyles.gridBorderColor,
                    width: 1,
                  ),
                  horizontalInside: BorderSide(
                    color: ScheduleStyles.gridBorderColor,
                    width: 1,
                  ),
                  top: BorderSide(
                    color: ScheduleStyles.gridBorderColor,
                    width: 1,
                  ),
                  right: BorderSide(
                    color: ScheduleStyles.gridBorderColor,
                    width: 1,
                  ),
                  left: BorderSide(
                    color: ScheduleStyles.gridBorderColor,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: ScheduleStyles.gridBorderColor,
                    width: 1,
                  ),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: ScheduleStyles.headerBgColor,
                    ),
                    children: weekLabels.asMap().entries.map((entry) {
                      final i = entry.key;
                      final label = entry.value;
                      final fullDayName = DateFormat(
                        'EEEE',
                      ).format(DateTime(2024, 1, 7 + i));
                      final isWeekend = settings.weeklyOffDays.contains(
                        fullDayName,
                      );

                      return Container(
                        height: headerHeight,
                        alignment: Alignment.center,
                        color: isWeekend ? Colors.grey.shade50 : null,
                        child: Text(
                          label,
                          style: isWeekend
                              ? ScheduleStyles.weekendLabelStyle
                              : ScheduleStyles.weekdayLabelStyle,
                        ),
                      );
                    }).toList(),
                  ),
                  ...weeks.map((week) {
                    return TableRow(
                      children: week.map((day) {
                        final isOutside = day.month != selectedDate.month;
                        if (isOutside) {
                          return Container(
                            height: rowHeight,
                            color: ScheduleStyles.cellBgColor,
                          );
                        }

                        final isToday = isSameDay(day, DateTime.now());
                        final isSelected = isSameDay(day, selectedDate);
                        final closedReasonAsync = ref.watch(
                          isOfficeClosedProvider(day),
                        );

                        final fullDayName = DateFormat('EEEE').format(day);
                        final isWeekend = settings.weeklyOffDays.contains(
                          fullDayName,
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
                            height: rowHeight,
                            color: isSelected
                                ? Colors.blue.withOpacity(0.05)
                                : ScheduleStyles.cellBgColor,
                            child: closedReasonAsync.when(
                              data: (reason) {
                                if (reason != null) {
                                  Widget textWidget = Text(
                                    reason.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.withOpacity(0.3),
                                      letterSpacing: 1,
                                    ),
                                  );

                                  if (isWeekend) {
                                    textWidget = RotatedBox(
                                      quarterTurns: 3,
                                      child: textWidget,
                                    );
                                  }

                                  return Container(
                                    width: double.infinity,
                                    color: Colors.red.withOpacity(0.02),
                                    child: Column(
                                      children: [
                                        _DayChip(day: day, isToday: isToday),
                                        Expanded(
                                          child: Center(child: textWidget),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return _MonthlyCellContent(
                                  day: day,
                                  isToday: isToday,
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _MonthlyCellContent extends ConsumerWidget {
  final DateTime day;
  final bool isToday;
  const _MonthlyCellContent({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleByDateProvider(day));
    return scheduleAsync.when(
      data: (view) {
        final allSessions = view.sessionsByTimeSlot.values
            .expand((l) => l)
            .toList();

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayChip(day: day, isToday: isToday),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...allSessions
                          .take(10)
                          .map((s) => CompactCard(session: s)),
                      if (allSessions.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            '+${allSessions.length - 10}',
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.black38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  const _DayChip({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(bottom: 2, right: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade700 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isToday ? Colors.white : Colors.black87,
          fontSize: 12,
          height: .8,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
