import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/session_providers.dart';
import 'daily_view.dart';
import 'monthly_view.dart';
import 'schedule_all_page.dart';
import 'weekly_view.dart';
import 'widgets/schedule_drawer_filter.dart';
import 'widgets/schedule_filter_bar.dart';

class ScheduleSpecificPage extends ConsumerStatefulWidget {
  final String? clientId;
  final String? employeeId;

  const ScheduleSpecificPage({super.key, this.clientId, this.employeeId});

  @override
  ConsumerState<ScheduleSpecificPage> createState() =>
      _ScheduleSpecificPageState();
}

class _ScheduleSpecificPageState extends ConsumerState<ScheduleSpecificPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _updateFilter();
  }

  @override
  void didUpdateWidget(ScheduleSpecificPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clientId != oldWidget.clientId ||
        widget.employeeId != oldWidget.employeeId) {
      _updateFilter();
    }
  }

  @override
  void dispose() {
    Future.microtask(() {
      ref.read(scheduleFilterProvider.notifier).clear();
    });
    super.dispose();
  }

  void _updateFilter() {
    Future.microtask(() {
      ref
          .read(scheduleFilterProvider.notifier)
          .setFilter(
            ScheduleFilter(
              clientId: widget.clientId,
              employeeId: widget.employeeId,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(plannerViewNotifierProvider);
    final filter = ref.watch(scheduleFilterProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: ScheduleDrawerFilter(
        fixedClientId: widget.clientId,
        fixedEmployeeId: widget.employeeId,
      ),
      body: Column(
        children: [
          _buildHeader(context, ref, filter),
          const ScheduleFilterBar(),
          Expanded(child: _buildMainView(view)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ScheduleFilter filter,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Schedule Planner',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                icon: const Icon(LucideIcons.filter, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  String path = '/admin/schedule/add';
                  if (widget.clientId != null)
                    path += '?clientId=${widget.clientId}';
                  if (widget.employeeId != null)
                    path += '?employeeId=${widget.employeeId}';
                  context.go(path);
                },
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text(
                  'Add Session',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainView(PlannerView view) {
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
