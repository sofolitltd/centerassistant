import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/leave.dart';
import '/core/providers/auth_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';

class EmployeeLeavePage extends ConsumerWidget {
  const EmployeeLeavePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final employeeId = authState.employeeId;

    if (employeeId == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final leavesAsync = ref.watch(leavesByEntityProvider(employeeId));
    final employeeAsync = ref.watch(employeeByIdProvider(employeeId));
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
                Text('Leave Management', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Leave Summary',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildSummaryGrid(leavesAsync, employeeAsync, width),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/employee/leave/apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply Leave',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 48),
            Text(
              'Recent History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLeaveHistory(context, leavesAsync, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
    AsyncValue<List<Leave>> leavesAsync,
    AsyncValue<dynamic> employeeAsync,
    double width,
  ) {
    return leavesAsync.when(
      data: (leaves) {
        double calculateUsed(LeaveType type) {
          return leaves
              .where(
                (l) => l.leaveType == type && l.status == LeaveStatus.approved,
              )
              .fold(
                0.0,
                (sum, l) =>
                    sum + (l.duration == LeaveDuration.full ? 1.0 : 0.5),
              );
        }

        final annualUsed = calculateUsed(LeaveType.annual);
        final sickUsed = calculateUsed(LeaveType.sick);
        final causalUsed = calculateUsed(LeaveType.causal);

        final crossAxisCount = width > 1100 ? 4 : (width > 700 ? 2 : 1);

        String formatCount(double count) {
          if (count == count.toInt().toDouble()) {
            return count.toInt().toString();
          }
          return count.toStringAsFixed(1);
        }

        return employeeAsync.when(
          data: (employee) {
            final carriedForward = employee?.carriedForwardLeaves ?? 0;
            final totalAnnualAvailable = 18 + carriedForward;

            return MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: 4,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryCard(
                    'Annual Leave',
                    '${formatCount(annualUsed)}/$totalAnnualAvailable',
                    carriedForward > 0
                        ? 'Includes $carriedForward carried forward'
                        : 'days remaining',
                    LucideIcons.userCheck,
                    const Color(0xFF1976D2),
                  );
                }
                if (index == 1) {
                  return _buildSummaryCard(
                    'Sick Leave',
                    '${formatCount(sickUsed)}/10',
                    'days remaining',
                    LucideIcons.stethoscope,
                    const Color(0xFFFFA000),
                  );
                }
                if (index == 2) {
                  return _buildSummaryCard(
                    'Causal Leave',
                    '${formatCount(causalUsed)}/5',
                    'days remaining',
                    LucideIcons.briefcase,
                    const Color(0xFF388E3C),
                  );
                }
                return _buildSummaryCard(
                  'Unpaid Leave',
                  'Available',
                  'When Needed',
                  LucideIcons.calendarX,
                  const Color(0xFFD32F2F),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistory(
    BuildContext context,
    AsyncValue<List<Leave>> leavesAsync,
    WidgetRef ref,
  ) {
    return leavesAsync.when(
      data: (leaves) {
        if (leaves.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No history found'),
            ),
          );
        }
        // Force sort by date descending (Newest date first)
        final sorted = List<Leave>.from(leaves)
          ..sort((a, b) => b.date.compareTo(a.date));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final leave = sorted[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getLeaveColor(
                    leave.leaveType,
                  ).withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: _getLeaveColor(leave.leaveType),
                  ),
                ),
                title: Text(
                  DateFormat('MMMM dd, yyyy').format(leave.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${leave.leaveType.name.toUpperCase()} • ${leave.duration.name.toUpperCase()} DAY',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(leave.status),
                    const SizedBox(width: 8),
                    if (leave.status == LeaveStatus.pending) ...[
                      IconButton(
                        tooltip: 'Edit Application',
                        icon: const Icon(
                          LucideIcons.edit2,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: () => _showEditDialog(context, ref, leave),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _showConfirmDialog(
                          context,
                          'Delete Application',
                          'Are you sure you want to delete this pending leave application?',
                          () => ref
                              .read(leaveServiceProvider)
                              .removeLeave(leave.id),
                        ),
                      ),
                    ],
                    if (leave.status == LeaveStatus.approved)
                      IconButton(
                        tooltip: 'Request Cancellation',
                        icon: const Icon(
                          LucideIcons.rotateCcw,
                          size: 18,
                          color: Colors.orange,
                        ),
                        onPressed: () => _showConfirmDialog(
                          context,
                          'Request Cancellation',
                          'Are you sure you want to request cancellation for this approved leave? This will be sent to the administrator for approval.',
                          () => ref
                              .read(leaveServiceProvider)
                              .requestCancel(leave.id),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Leave leave) async {
    final theme = Theme.of(context);
    LeaveType selectedType = leave.leaveType;
    LeaveDuration selectedDuration = leave.duration;
    final reasonController = TextEditingController(text: leave.reason ?? '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Edit Pending Leave',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(leave.date),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Leave Type',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<LeaveType>(
                  value: selectedType,
                  isDense: true,
                  items: LeaveType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.name.toUpperCase(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Duration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<LeaveDuration>(
                  value: selectedDuration,
                  items: LeaveDuration.values
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            '${d.name} day'.toUpperCase(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedDuration = v!),
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notes (Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration(hint: 'Reason for leave...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // To keep it simple, we delete and re-add or we could add an update method to service
                await ref.read(leaveServiceProvider).removeLeave(leave.id);
                await ref
                    .read(leaveServiceProvider)
                    .addLeave(
                      employeeId: leave.employeeId,
                      date: leave.date,
                      reason: reasonController.text,
                      leaveType: selectedType,
                      duration: selectedDuration,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    Color color;
    String label = status.name.toUpperCase();
    switch (status) {
      case LeaveStatus.approved:
        color = Colors.green;
        break;
      case LeaveStatus.rejected:
        color = Colors.red;
        break;
      case LeaveStatus.pending:
        color = Colors.orange;
        break;
      case LeaveStatus.cancelled:
        color = Colors.grey;
        break;
      case LeaveStatus.cancelRequest:
        color = Colors.purple;
        label = 'CANCEL REQ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
    );
  }

  Color _getLeaveColor(LeaveType type) {
    switch (type) {
      case LeaveType.annual:
        return Colors.blue;
      case LeaveType.sick:
        return Colors.orange;
      case LeaveType.causal:
        return Colors.green;
      case LeaveType.unpaid:
        return Colors.red;
    }
  }
}
