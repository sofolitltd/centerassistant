import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import 'widget/daily_view.dart';
import 'widget/monthly_view.dart';
import 'widget/weekly_view.dart';

enum PlannerView { daily, weekly, monthly }

class PlannerViewNotifier extends Notifier<PlannerView> {
  @override
  PlannerView build() => PlannerView.daily;
  void setView(PlannerView view) => state = view;
}

final plannerViewNotifierProvider =
    NotifierProvider<PlannerViewNotifier, PlannerView>(PlannerViewNotifier.new);

// Common Styling
const gridBorderColor = Colors.blueGrey;
const headerBgColor = Colors.white;
const cellBgColor = Colors.transparent;

class SchedulePlannerPage extends ConsumerStatefulWidget {
  final String? clientId;
  final String? employeeId;

  const SchedulePlannerPage({super.key, this.clientId, this.employeeId});

  @override
  ConsumerState<SchedulePlannerPage> createState() =>
      _SchedulePlannerPageState();
}

class _SchedulePlannerPageState extends ConsumerState<SchedulePlannerPage> {
  @override
  void initState() {
    super.initState();
    // Use microtask to set filter after first build to avoid provider modification during build
    Future.microtask(() {
      ref.read(scheduleFilterProvider.notifier).state = ScheduleFilter(
        clientId: widget.clientId,
        employeeId: widget.employeeId,
      );
    });
  }

  @override
  void didUpdateWidget(SchedulePlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clientId != oldWidget.clientId ||
        widget.employeeId != oldWidget.employeeId) {
      Future.microtask(() {
        ref.read(scheduleFilterProvider.notifier).state = ScheduleFilter(
          clientId: widget.clientId,
          employeeId: widget.employeeId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(plannerViewNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final filter = ref.watch(scheduleFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context, ref, view, selectedDate, filter),
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
    ScheduleFilter filter,
  ) {
    String? filterName;
    if (filter.clientId != null) {
      final clients = ref.watch(clientsProvider).value ?? [];
      filterName = clients
          .where((c) => c.id == filter.clientId)
          .firstOrNull
          ?.name;
    } else if (filter.employeeId != null) {
      final employees = ref.watch(employeesProvider).value ?? [];
      filterName = employees
          .where((e) => e.id == filter.employeeId)
          .firstOrNull
          ?.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      InkWell(
                        onTap: () {
                          ref.read(scheduleFilterProvider.notifier).state =
                              const ScheduleFilter();
                          context.go('/admin/schedule');
                        },
                        child: Text(
                          'Schedule',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: filterName != null ? Colors.grey : null,
                              ),
                        ),
                      ),
                      if (filterName != null) ...[
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        Text(
                          filterName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Schedules',
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      if (filterName != null) ...[
                        const SizedBox(width: 12),
                        Chip(
                          label: Text(
                            filter.clientId != null
                                ? 'Client: $filterName'
                                : 'Therapist: $filterName',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onDeleted: () {
                            ref.read(scheduleFilterProvider.notifier).state =
                                const ScheduleFilter();
                            context.go('/admin/schedule');
                          },
                          deleteIconColor: Colors.red,
                          backgroundColor: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      String path = '/admin/schedule/add';
                      if (filter.clientId != null) {
                        path += '?clientId=${filter.clientId}';
                      }
                      if (filter.employeeId != null) {
                        path += '?employeeId=${filter.employeeId}';
                      }
                      context.push(path);
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
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
            ],
          ),
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
                return Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
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
                            side: const BorderSide(color: gridBorderColor),
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
      children: [
        _ViewMenuButton(
          label: 'Day',
          isSelected: currentView == PlannerView.daily,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.daily),
        ),
        const SizedBox(width: 4),
        _ViewMenuButton(
          label: 'Week',
          isSelected: currentView == PlannerView.weekly,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.weekly),
        ),
        const SizedBox(width: 4),
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
        return const DailyView();
      case PlannerView.weekly:
        return const WeeklyView();
      case PlannerView.monthly:
        return const MonthlyView();
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
