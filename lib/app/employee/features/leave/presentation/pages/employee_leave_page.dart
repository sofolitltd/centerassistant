import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/leave.dart';
import '/core/providers/auth_providers.dart';
import '/core/providers/leave_providers.dart';

class EmployeeLeavePage extends ConsumerStatefulWidget {
  const EmployeeLeavePage({super.key});

  @override
  ConsumerState<EmployeeLeavePage> createState() => _EmployeeLeavePageState();
}

class _EmployeeLeavePageState extends ConsumerState<EmployeeLeavePage> {
  final List<DateTime> _selectedDates = [];
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final employeeId = authState.employeeId;

    if (employeeId == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final leavesAsync = ref.watch(leavesByEntityProvider(employeeId));
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/employee/layout'),
                  child: Text(
                    'Overview',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text('Leave Management', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Leave Management',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mark your unavailability or request leaves here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildAddSection()),
                  const SizedBox(width: 32),
                  Expanded(flex: 6, child: _buildListSection(leavesAsync)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddSection(),
                  const SizedBox(height: 32),
                  _buildListSection(leavesAsync),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .start,
      children: [
        //
        Text(
          'Apply for Leave',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        //
        Card(
          elevation: 0,
          margin: .zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date(s)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._selectedDates.map(
                        (date) => Chip(
                          label: Text(DateFormat('dd MMM, yyyy').format(date)),
                          onDeleted: () {
                            setState(() {
                              _selectedDates.remove(date);
                            });
                          },
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Add Date'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            final normalized = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                            if (!_selectedDates.any((d) => d == normalized)) {
                              setState(() => _selectedDates.add(normalized));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reason',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason for leave...',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _selectedDates.isEmpty
                        ? null
                        : () async {
                            final authState = ref.read(authProvider);
                            final service = ref.read(leaveServiceProvider);
                            for (final date in _selectedDates) {
                              await service.addLeave(
                                entityId: authState.employeeId!,
                                entityType: LeaveEntityType.employee,
                                date: date,
                                reason: _reasonController.text.trim(),
                              );
                            }

                            _reasonController.clear();
                            setState(() => _selectedDates.clear());

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave applied successfully'),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(AsyncValue<List<Leave>> leavesAsync) {
    final theme = Theme.of(context);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Leaves',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        leavesAsync.when(
          data: (leaves) {
            if (leaves.isEmpty) {
              return Card(
                elevation: 0,
                margin: .zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text(
                      'No leaves marked yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                final leave = leaves[index];
                final bool isPast = leave.date.isBefore(today);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPast
                          ? Colors.grey.shade100
                          : Colors.red.shade50,
                      child: Icon(
                        LucideIcons.calendarX,
                        color: isPast
                            ? Colors.grey.shade500
                            : Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      DateFormat('dd MMM, yyyy').format(leave.date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(leave.reason ?? 'No reason provided'),
                    trailing: isPast
                        ? null
                        : IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () =>
                                _showDeleteConfirm(context, leave.id),
                          ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, String leaveId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave'),
        content: const Text(
          'Are you sure you want to cancel this leave application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(leaveServiceProvider).removeLeave(leaveId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
