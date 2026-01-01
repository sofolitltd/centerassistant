import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/auth_providers.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/schedule_template_providers.dart';
import '/core/providers/time_slot_providers.dart';

class EmployeeClientsPage extends ConsumerWidget {
  const EmployeeClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final String? employeeId = authState.employeeId;

    final templatesAsync = ref.watch(allScheduleTemplatesProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);

    if (employeeId == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/employee/dashboard'),
                  child: Text(
                    'Overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('My Clients', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'My Assigned Clients',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: templatesAsync.when(
                data: (templates) => clientsAsync.when(
                  data: (allClients) => timeSlotsAsync.when(
                    data: (timeSlots) {
                      final slotMap = {for (var s in timeSlots) s.id: s};

                      // Map to store: ClientID -> List of "Day (StartTime - EndTime)"
                      final Map<String, List<String>> clientScheduleInfo = {};

                      for (final template in templates) {
                        final employeeRules = template.rules.where(
                          (r) => r.employeeId == employeeId,
                        );

                        if (employeeRules.isNotEmpty) {
                          final List<String> scheduleStrings = employeeRules
                              .map((r) {
                                final slot = slotMap[r.timeSlotId];
                                final time = slot != null
                                    ? ' (${slot.startTime} - ${slot.endTime})'
                                    : '';
                                return '${r.dayOfWeek}$time';
                              })
                              .toList();

                          if (clientScheduleInfo.containsKey(
                            template.clientId,
                          )) {
                            clientScheduleInfo[template.clientId]!.addAll(
                              scheduleStrings,
                            );
                          } else {
                            clientScheduleInfo[template.clientId] =
                                scheduleStrings;
                          }
                        }
                      }

                      final assignedClients = allClients
                          .where((c) => clientScheduleInfo.containsKey(c.id))
                          .toList();

                      if (assignedClients.isEmpty) {
                        return _buildEmptyState(theme);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: assignedClients.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final client = assignedClients[index];
                          final schedules = clientScheduleInfo[client.id] ?? [];

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: client.image.isNotEmpty
                                        ? NetworkImage(client.image)
                                        : null,
                                    child: client.image.isEmpty
                                        ? const Icon(LucideIcons.user)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: schedules
                                              .map(
                                                (info) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .secondaryContainer
                                                        .withValues(alpha: 0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    info,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme
                                                          .colorScheme
                                                          .onSecondaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) =>
                        Center(child: Text('Error loading time slots: $e')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text('Error loading clients: $e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) =>
                    Center(child: Text('Error loading schedules: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Assigned Clients',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are not currently assigned to any client schedules.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
