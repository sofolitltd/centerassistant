import 'package:center_assistant/app/admin/features/schedule/presentation/pages/home/widgets/schedule_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import 'daily_view.dart';
import 'monthly_view.dart';
import 'weekly_view.dart';
import 'widgets/schedule_drawer_filter.dart';

enum PlannerView { daily, weekly, monthly }

class PlannerViewNotifier extends Notifier<PlannerView> {
  @override
  PlannerView build() => PlannerView.daily;
  void setView(PlannerView view) => state = view;
}

final plannerViewNotifierProvider =
    NotifierProvider<PlannerViewNotifier, PlannerView>(PlannerViewNotifier.new);

class ScheduleAllPage extends ConsumerStatefulWidget {
  const ScheduleAllPage({super.key});

  @override
  ConsumerState<ScheduleAllPage> createState() => _ScheduleAllPageState();
}

class _ScheduleAllPageState extends ConsumerState<ScheduleAllPage> {
  @override
  void initState() {
    super.initState();
    // Fresh start: Reset filters and date when entering the global schedule page
    Future.microtask(() {
      if (mounted) {
        ref.read(scheduleFilterProvider.notifier).clear();
        ref.read(selectedDateProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(plannerViewNotifierProvider);
    final filter = ref.watch(scheduleFilterProvider);

    return Scaffold(
      endDrawer: const ScheduleDrawerFilter(),
      body: Column(
        children: [
          _buildHeader(context, ref, filter),

          //
          const ScheduleFilterBar(),

          //
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
    final clientsAsync = ref.watch(clientsProvider);
    final employeesAsync = ref.watch(employeesProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBreadcrumbs(context, ref, filter),
                    const SizedBox(height: 8),
                    _buildTitleWithChips(
                      context,
                      filter,
                      ref,
                      clientsAsync,
                      employeesAsync,
                    ),
                  ],
                ),
              ),
              _buildAddButton(context, filter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(
    BuildContext context,
    WidgetRef ref,
    ScheduleFilter filter,
  ) {
    final bool hasFilter =
        filter.clientId != null ||
        filter.employeeId != null ||
        filter.serviceType != null ||
        filter.status != null ||
        filter.isInclusive != null;

    return Row(
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
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        InkWell(
          onTap: () {
            ref.read(scheduleFilterProvider.notifier).clear();
            context.go('/admin/schedule');
          },
          child: Text(
            'Schedule',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasFilter ? Colors.grey : null,
            ),
          ),
        ),
        if (hasFilter) ...[
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          const Text('Filtered View', style: TextStyle(fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildTitleWithChips(
    BuildContext context,
    ScheduleFilter filter,
    WidgetRef ref,
    AsyncValue<List<dynamic>> clientsAsync,
    AsyncValue<List<dynamic>> employeesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedules',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        if (filter.clientId != null ||
            filter.employeeId != null ||
            filter.serviceType != null ||
            filter.status != null ||
            filter.isInclusive != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (filter.clientId != null)
                _buildFilterChip(
                  label:
                      'Client: ${clientsAsync.value?.where((c) => c.id == filter.clientId).firstOrNull?.name ?? '...'}',
                  onDeleted: () => ref
                      .read(scheduleFilterProvider.notifier)
                      .setFilter(filter.copyWith(clientId: () => null)),
                ),
              if (filter.employeeId != null)
                _buildFilterChip(
                  label:
                      'Therapist: ${employeesAsync.value?.where((e) => e.id == filter.employeeId).firstOrNull?.name ?? '...'}',
                  onDeleted: () => ref
                      .read(scheduleFilterProvider.notifier)
                      .setFilter(filter.copyWith(employeeId: () => null)),
                ),
              if (filter.serviceType != null)
                _buildFilterChip(
                  label: 'Service: ${filter.serviceType}',
                  onDeleted: () => ref
                      .read(scheduleFilterProvider.notifier)
                      .setFilter(filter.copyWith(serviceType: () => null)),
                ),
              if (filter.status != null)
                _buildFilterChip(
                  label: 'Status: ${filter.status!.name}',
                  onDeleted: () => ref
                      .read(scheduleFilterProvider.notifier)
                      .setFilter(filter.copyWith(status: () => null)),
                ),
              if (filter.isInclusive != null)
                _buildFilterChip(
                  label: filter.isInclusive! ? 'Inclusive' : 'Exclusive',
                  onDeleted: () => ref
                      .read(scheduleFilterProvider.notifier)
                      .setFilter(filter.copyWith(isInclusive: () => null)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onDeleted: onDeleted,
      deleteIconColor: Colors.red,
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildAddButton(BuildContext context, ScheduleFilter filter) {
    return ElevatedButton.icon(
      onPressed: () {
        String path = '/admin/schedule/add';
        if (filter.clientId != null) path += '?clientId=${filter.clientId}';
        if (filter.employeeId != null) {
          path += '?employeeId=${filter.employeeId}';
        }
        context.go(path);
      },
      icon: const Icon(LucideIcons.plus, size: 16),
      label: const Text('Add Schedule'),
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
