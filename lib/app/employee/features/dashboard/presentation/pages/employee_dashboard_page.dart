import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/schedule_template.dart';
import '/core/models/time_slot.dart';
import '/core/providers/auth_providers.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/schedule_template_providers.dart';
import '/core/providers/time_slot_providers.dart';

class EmployeeDashboardPage extends ConsumerWidget {
  const EmployeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _EmployeeDashboardContent();
  }
}

class _EmployeeDashboardContent extends ConsumerWidget {
  const _EmployeeDashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final String? employeeId = authState.employeeId;

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (employeeId == null) {
      return const Scaffold(
        body: Center(child: Text('User session not found')),
      );
    }

    final employeeAsync = ref.watch(employeeByIdProvider(employeeId));
    final templatesAsync = ref.watch(allScheduleTemplatesProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final leavesAsync = ref.watch(leavesByEntityProvider(employeeId));

    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 1100;

    // Helper to convert time strings to total minutes from midnight for proper comparison
    int timeToMinutes(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return 0;
      final trimmed = timeStr.trim();
      try {
        final patterns = ['h:mm a', 'hh:mm a', 'H:mm', 'HH:mm'];
        for (var pattern in patterns) {
          try {
            final dateTime = DateFormat(pattern).parse(trimmed);
            return dateTime.hour * 60 + dateTime.minute;
          } catch (_) {}
        }
        try {
          final dateTime = DateFormat.jm().parse(trimmed);
          return dateTime.hour * 60 + dateTime.minute;
        } catch (_) {}
        return 0;
      } catch (e) {
        return 0;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/'),
                  child: Text(
                    'Home',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Overview', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            employeeAsync.when(
              data: (employee) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back, ${employee?.name ?? 'Employee'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Dynamic Stats Grid (Masonry)
                  templatesAsync.when(
                    data: (templates) => leavesAsync.when(
                      data: (leaves) => clientsAsync.when(
                        data: (clients) => timeSlotsAsync.when(
                          data: (timeSlots) {
                            final today = DateTime.now();
                            final todayName = DateFormat('EEEE').format(today);
                            final slotMap = {for (var s in timeSlots) s.id: s};

                            final isOnLeaveToday = leaves.any(
                              (l) =>
                                  l.date.year == today.year &&
                                  l.date.month == today.month &&
                                  l.date.day == today.day,
                            );

                            final myRules = templates
                                .expand(
                                  (t) => t.rules.map(
                                    (r) => {'rule': r, 'clientId': t.clientId},
                                  ),
                                )
                                .where(
                                  (map) =>
                                      (map['rule'] as ScheduleRule)
                                          .employeeId ==
                                      employeeId,
                                )
                                .toList();

                            final assignedClientsCount = myRules
                                .map((m) => m['clientId'])
                                .toSet()
                                .length;
                            final weeklySessionsCount = myRules.length;

                            final todaySessions = myRules
                                .where(
                                  (m) =>
                                      (m['rule'] as ScheduleRule).dayOfWeek ==
                                      todayName,
                                )
                                .toList();

                            todaySessions.sort((a, b) {
                              final slotA =
                                  slotMap[(a['rule'] as ScheduleRule)
                                      .timeSlotId];
                              final slotB =
                                  slotMap[(b['rule'] as ScheduleRule)
                                      .timeSlotId];
                              return timeToMinutes(
                                slotA?.startTime,
                              ).compareTo(timeToMinutes(slotB?.startTime));
                            });

                            final todaySessionsCount = isOnLeaveToday
                                ? 0
                                : todaySessions.length;

                            String sessionStatusText = 'None';
                            Color sessionStatusColor = Colors.purple;
                            IconData sessionStatusIcon =
                                LucideIcons.arrowRightCircle;

                            if (todaySessions.isNotEmpty && !isOnLeaveToday) {
                              final currentMinutes =
                                  today.hour * 60 + today.minute;

                              bool foundActive = false;
                              for (var m in todaySessions) {
                                final slot =
                                    slotMap[(m['rule'] as ScheduleRule)
                                        .timeSlotId];
                                if (slot != null) {
                                  final start = timeToMinutes(slot.startTime);
                                  final end = timeToMinutes(slot.endTime);
                                  // Buffer of 5 minutes before/after for "Active" state
                                  if (currentMinutes >= start &&
                                      currentMinutes < end) {
                                    sessionStatusText = 'Running Now';
                                    sessionStatusColor = Colors.green;
                                    sessionStatusIcon = LucideIcons.playCircle;
                                    foundActive = true;
                                    break;
                                  }
                                }
                              }

                              if (!foundActive) {
                                try {
                                  final next = todaySessions.firstWhere((m) {
                                    final slot =
                                        slotMap[(m['rule'] as ScheduleRule)
                                            .timeSlotId];
                                    return timeToMinutes(slot?.startTime) >
                                        currentMinutes;
                                  });
                                  final slot =
                                      slotMap[(next['rule'] as ScheduleRule)
                                          .timeSlotId];
                                  sessionStatusText = slot?.startTime ?? 'None';
                                } catch (_) {
                                  sessionStatusText = 'All Done';
                                  sessionStatusColor = Colors.grey;
                                  sessionStatusIcon = LucideIcons.checkCircle;
                                }
                              }
                            }

                            return MasonryGridView.count(
                              crossAxisCount: width > 1300
                                  ? 4
                                  : (width > 800 ? 2 : 1),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildStatCard(
                                    context,
                                    'Total Clients',
                                    assignedClientsCount.toString(),
                                    LucideIcons.users,
                                    Colors.blue,
                                    onTap: () =>
                                        context.go('/employee/clients'),
                                  );
                                }
                                if (index == 1) {
                                  return _buildStatCard(
                                    context,
                                    'Weekly Sessions',
                                    weeklySessionsCount.toString(),
                                    LucideIcons.calendarCheck,
                                    Colors.green,
                                    onTap: () =>
                                        context.go('/employee/schedule'),
                                  );
                                }
                                if (index == 2) {
                                  return _buildStatCard(
                                    context,
                                    'Today\'s Workload',
                                    isOnLeaveToday
                                        ? 'ON LEAVE'
                                        : todaySessionsCount.toString(),
                                    LucideIcons.clock,
                                    isOnLeaveToday ? Colors.red : Colors.orange,
                                    onTap: () =>
                                        context.go('/employee/schedule'),
                                  );
                                }
                                return _buildStatCard(
                                  context,
                                  'Next Session',
                                  isOnLeaveToday ? 'NONE' : sessionStatusText,
                                  isOnLeaveToday
                                      ? LucideIcons.calendarX
                                      : sessionStatusIcon,
                                  isOnLeaveToday
                                      ? Colors.grey
                                      : sessionStatusColor,
                                  onTap: () => context.go('/employee/schedule'),
                                );
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const Text('Error loading data'),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, _) => const Text('Error loading clients'),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, _) => const Text('Error loading leaves'),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, _) => const Text('Error loading schedule'),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),

            const SizedBox(height: 32),

            if (!isMobile)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTodaySchedule(
                      context,
                      ref,
                      employeeId,
                      templatesAsync,
                      timeSlotsAsync,
                      leavesAsync,
                      timeToMinutes,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildQuickActions(context)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTodaySchedule(
                    context,
                    ref,
                    employeeId,
                    templatesAsync,
                    timeSlotsAsync,
                    leavesAsync,
                    timeToMinutes,
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule(
    BuildContext context,
    WidgetRef ref,
    String employeeId,
    AsyncValue<List<ScheduleTemplate>> templatesAsync,
    AsyncValue<List<TimeSlot>> timeSlotsAsync,
    AsyncValue<List<dynamic>> leavesAsync,
    int Function(String?) timeToMinutes,
  ) {
    final theme = Theme.of(context);
    return _buildSection(
      context,
      'Today\'s Schedule',
      leavesAsync.when(
        data: (leaves) {
          final today = DateTime.now();
          final isOnLeaveToday = leaves.any(
            (l) =>
                (l as dynamic).date.year == today.year &&
                (l as dynamic).date.month == today.month &&
                (l as dynamic).date.day == today.day,
          );

          if (isOnLeaveToday) {
            final leave = leaves.firstWhere(
              (l) =>
                  (l as dynamic).date.year == today.year &&
                  (l as dynamic).date.month == today.month &&
                  (l as dynamic).date.day == today.day,
            );
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarX,
                    color: Colors.red.shade700,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are on leave today',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      if ((leave as dynamic).reason != null &&
                          (leave as dynamic).reason!.isNotEmpty)
                        Text(
                          'Reason: ${(leave as dynamic).reason}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }

          return templatesAsync.when(
            data: (templates) => timeSlotsAsync.when(
              data: (timeSlots) {
                final todayName = DateFormat('EEEE').format(today);
                final slotMap = {for (var s in timeSlots) s.id: s};

                final todaySessions = templates
                    .expand(
                      (t) => t.rules.map(
                        (r) => {
                          'rule': r,
                          'clientId': t.clientId,
                          'clientName':
                              ref
                                  .watch(clientsProvider)
                                  .value
                                  ?.where((c) => c.id == t.clientId)
                                  .firstOrNull
                                  ?.name ??
                              'Unknown',
                        },
                      ),
                    )
                    .where(
                      (m) =>
                          (m['rule'] as ScheduleRule).employeeId ==
                              employeeId &&
                          (m['rule'] as ScheduleRule).dayOfWeek == todayName,
                    )
                    .toList();

                if (todaySessions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No sessions scheduled for today.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                todaySessions.sort((a, b) {
                  final slotA = slotMap[(a['rule'] as ScheduleRule).timeSlotId];
                  final slotB = slotMap[(b['rule'] as ScheduleRule).timeSlotId];
                  return timeToMinutes(
                    slotA?.startTime,
                  ).compareTo(timeToMinutes(slotB?.startTime));
                });

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaySessions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final map = todaySessions[index];
                    final rule = map['rule'] as ScheduleRule;
                    final slot = slotMap[rule.timeSlotId];
                    final clientName = map['clientName'] as String;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          clientName[0],
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        slot != null
                            ? '${slot.startTime} - ${slot.endTime}'
                            : 'Time Slot',
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Error loading slots'),
            ),
            loading: () => const SizedBox(),
            error: (_, _) => const Text('Error loading schedule'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Error checking leave status'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return _buildSection(
      context,
      'Quick Actions',
      Column(
        children: [
          _buildActionTile(
            context,
            LucideIcons.calendar,
            'Weekly Schedule',
            () => context.go('/employee/schedule'),
          ),
          _buildActionTile(
            context,
            LucideIcons.users,
            'My Clients',
            () => context.go('/employee/clients'),
          ),
          _buildActionTile(
            context,
            LucideIcons.calendarX,
            'Leave Management',
            () => context.go('/employee/leave'),
          ),
          _buildActionTile(
            context,
            LucideIcons.user,
            'Edit Profile',
            () => context.go('/employee/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(padding: const EdgeInsets.all(20), child: content),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
