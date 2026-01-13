import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/providers/session_providers.dart';
import '/core/providers/time_slot_providers.dart';
import '../widgets/add_session_dialog.dart';
import '../widgets/session_card.dart';

enum PlannerView { daily, weekly, monthly }

class PlannerViewNotifier extends Notifier<PlannerView> {
  @override
  PlannerView build() => PlannerView.daily;
  void setView(PlannerView view) => state = view;
}

final plannerViewNotifierProvider =
    NotifierProvider<PlannerViewNotifier, PlannerView>(PlannerViewNotifier.new);

// Common Styling
const _gridBorderColor = Colors.blueGrey;
const _headerBgColor = Colors.white;
const _cellBgColor = Colors.transparent;

class SchedulePlannerPage extends ConsumerWidget {
  const SchedulePlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(plannerViewNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context, ref, view, selectedDate),
          Expanded(child: _buildMainView(context, ref, view, selectedDate)),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    PlannerView view,
    DateTime selectedDate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          //
          Row(
            crossAxisAlignment: .end,
            mainAxisAlignment: .spaceBetween,
            spacing: 16,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.go('/admin/dashboard'),
                        child: Text(
                          'Admin',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Text(
                        'Schedule',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedules',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),

              //
              ElevatedButton.icon(
                onPressed: () => _handleSync(context, ref, selectedDate),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Sync Month'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C10),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),

          //
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                // Toggle between Column for Mobile and Row for Desktop
                return Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    // 1. Date Navigation Section
                    Row(
                      mainAxisSize: isMobile
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(selectedDateProvider.notifier)
                              .setDate(DateTime.now()),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            side: const BorderSide(color: _gridBorderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chevron_left, size: 24),
                          onPressed: () =>
                              _navigateDate(ref, selectedDate, view, -1),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chevron_right, size: 24),
                          onPressed: () =>
                              _navigateDate(ref, selectedDate, view, 1),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatToolbarDate(selectedDate, view),
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (isMobile) const SizedBox(height: 12),

                    // 2. View Switcher Section
                    _buildViewMenu(ref, view),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMenu(WidgetRef ref, PlannerView currentView) {
    return Row(
      spacing: 4,
      children: [
        _ViewMenuButton(
          label: 'Day',
          isSelected: currentView == PlannerView.daily,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.daily),
        ),
        _ViewMenuButton(
          label: 'Week',
          isSelected: currentView == PlannerView.weekly,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.weekly),
        ),
        _ViewMenuButton(
          label: 'Month',
          isSelected: currentView == PlannerView.monthly,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.monthly),
        ),
      ],
    );
  }

  void _navigateDate(
    WidgetRef ref,
    DateTime current,
    PlannerView view,
    int delta,
  ) {
    DateTime next;
    if (view == PlannerView.daily) {
      next = current.add(Duration(days: delta));
    } else if (view == PlannerView.weekly) {
      next = current.add(Duration(days: delta * 7));
    } else {
      next = DateTime(current.year, current.month + delta, 1);
    }
    ref.read(selectedDateProvider.notifier).setDate(next);
  }

  String _formatToolbarDate(DateTime date, PlannerView view) {
    if (view == PlannerView.monthly) {
      return DateFormat('MMMM yyyy').format(date);
    }
    if (view == PlannerView.daily) {
      return DateFormat('EEEE, MMMM dd, yyyy').format(date);
    }
    final start = date.subtract(Duration(days: date.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('MMM dd').format(start)} – ${DateFormat('MMM dd, yyyy').format(end)}';
  }

  Widget _buildMainView(
    BuildContext context,
    WidgetRef ref,
    PlannerView view,
    DateTime date,
  ) {
    switch (view) {
      case PlannerView.daily:
        return const _DailyView();
      case PlannerView.weekly:
        return const _WeeklyView();
      case PlannerView.monthly:
        return const _MonthlyView();
    }
  }

  Future<void> _handleSync(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Month Instances'),
        content: Text(
          'Clone weekly templates into editable sessions for ${DateFormat('MMMM yyyy').format(date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Sync'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionServiceProvider).syncTemplatesToInstances(date);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instances generated successfully')),
        );
      }
    }
  }
}

class _ViewMenuButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewMenuButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DailyView extends ConsumerWidget {
  const _DailyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleViewProvider);

    return scheduleAsync.when(
      data: (view) {
        if (view.timeSlots.isEmpty) {
          return const Center(child: Text('No time slots available'));
        }

        return ScrollConfiguration(
          // This allows mouse dragging for a "click and drag" experience
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Optional: makes dragging feel smoother
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(388),
                    border: TableBorder(
                      borderRadius: BorderRadius.circular(4),
                      verticalInside: const BorderSide(
                        color: _gridBorderColor,
                        width: 1,
                      ),
                      top: const BorderSide(color: _gridBorderColor, width: 1),
                      right: const BorderSide(
                        color: _gridBorderColor,
                        width: 1,
                      ),
                      left: const BorderSide(color: _gridBorderColor, width: 1),
                      bottom: const BorderSide(
                        color: _gridBorderColor,
                        width: 1,
                      ),
                    ),
                    children: [
                      // 1. Header Row
                      TableRow(
                        decoration: const BoxDecoration(
                          color: _headerBgColor,
                          border: Border(
                            bottom: BorderSide(
                              color: _gridBorderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        children: view.timeSlots.map((slot) {
                          return Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${slot.startTime} - ${slot.endTime}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        slot.label,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (c) =>
                                      AddSessionDialog(timeSlotId: slot.id),
                                ),
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

                      // 2. Sessions Body Row
                      TableRow(
                        children: view.timeSlots.map((slot) {
                          final sessions =
                              view.sessionsByTimeSlot[slot.id] ?? [];
                          return Container(
                            color: _cellBgColor,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (sessions.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 40),
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
                                        bottom: 12,
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
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _WeeklyView extends ConsumerWidget {
  const _WeeklyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);

    // Calculate the start of the week (Sunday)
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

        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(80), // Time Gutter
              },
              defaultColumnWidth: const FlexColumnWidth(),
              border: const TableBorder(
                verticalInside: BorderSide(color: _gridBorderColor, width: 1),
                horizontalInside: BorderSide(color: _gridBorderColor, width: 1),
                top: BorderSide(color: _gridBorderColor, width: 1),
                right: BorderSide(color: _gridBorderColor, width: 1),
                left: BorderSide(color: _gridBorderColor, width: 1),
                bottom: BorderSide(color: _gridBorderColor, width: 1),
              ),
              children: [
                // 1. Weekly Header Row (Day Names & Dates)
                TableRow(
                  decoration: const BoxDecoration(color: _headerBgColor),
                  children: [
                    const SizedBox.shrink(), // Empty cell above time labels
                    ...weekDays.map((day) {
                      final isToday = isSameDay(day, DateTime.now());
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('EEE').format(day).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isToday
                                    ? Colors.blue.shade700
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 28,
                              height: 28,
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
                                  fontSize: 14,
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
                      );
                    }),
                  ],
                ),

                // 2. Weekly Grid Rows (One row per Time Slot)
                ...slots.map((slot) {
                  return TableRow(
                    children: [
                      // Time Label Cell
                      Container(
                        height: 120,
                        padding: const EdgeInsets.only(top: 12, right: 12),
                        alignment: Alignment.topRight,
                        child: Text(
                          slot.startTime,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black38,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      // Data Cells for each day
                      ...weekDays.map(
                        (day) => _WeeklyDayCell(day: day, slotId: slot.id),
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
  }
}

class _WeeklyDayCell extends ConsumerWidget {
  final DateTime day;
  final String slotId;

  const _WeeklyDayCell({required this.day, required this.slotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleByDateProvider(day));

    return Container(
      height: 120,
      color: _cellBgColor,
      child: scheduleAsync.when(
        data: (view) {
          final sessions = view.sessionsByTimeSlot[slotId] ?? [];
          if (sessions.isEmpty) return const SizedBox.shrink();

          return ListView.builder(
            padding: const EdgeInsets.all(6),
            itemCount: sessions.length,
            // Prevents listview from capturing scroll since it's inside a scrollable table
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (c, i) => _CompactCard(session: sessions[i]),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final SessionCardData session;
  const _CompactCard({required this.session});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        session.clientName,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MonthlyView extends ConsumerWidget {
  const _MonthlyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    // Calculate start of month and grid start (last Sunday of previous month)
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    );

    // Start grid at the beginning of the week (Sunday)
    final gridStart = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );

    // Generate 6 weeks to ensure the grid always fills the same space
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));
    final weeks = List.generate(6, (i) => days.sublist(i * 7, (i + 1) * 7));

    final weekLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Table(
          defaultColumnWidth: const FlexColumnWidth(),
          border: const TableBorder(
            verticalInside: BorderSide(color: _gridBorderColor, width: 1),
            horizontalInside: BorderSide(color: _gridBorderColor, width: 1),
            top: BorderSide(color: _gridBorderColor, width: 1),
            right: BorderSide(color: _gridBorderColor, width: 1),
            left: BorderSide(color: _gridBorderColor, width: 1),
            bottom: BorderSide(color: _gridBorderColor, width: 1),
          ),
          children: [
            // 1. Header Row (Day Names)
            TableRow(
              decoration: const BoxDecoration(color: _headerBgColor),
              children: weekLabels
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            // 2. Calendar Grid Rows
            ...weeks.map((week) {
              return TableRow(
                children: week.map((day) {
                  final isOutside = day.month != selectedDate.month;
                  final isToday = isSameDay(day, DateTime.now());
                  final isSelected = isSameDay(day, selectedDate);

                  return InkWell(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).setDate(day);
                      ref
                          .read(plannerViewNotifierProvider.notifier)
                          .setView(PlannerView.daily);
                    },
                    child: Container(
                      height: 140, // Consistent height for monthly view
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.05)
                          : _cellBgColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Number Header
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
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
                                '${day.day}',
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : (isOutside
                                            ? Colors.black26
                                            : Colors.black87),
                                  fontSize: 12,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          // Sessions Content
                          Expanded(child: _MonthlyCellContent(day: day)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCellContent extends ConsumerWidget {
  final DateTime day;

  const _MonthlyCellContent({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleByDateProvider(day));

    return scheduleAsync.when(
      data: (view) {
        final allSessions = view.sessionsByTimeSlot.values
            .expand((l) => l)
            .toList();
        if (allSessions.isEmpty) return const SizedBox.shrink();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...allSessions.take(3).map((s) => _CompactCard(session: s)),
            if (allSessions.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Text(
                  '+${allSessions.length - 3} more',
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
