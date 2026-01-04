import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/leave.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/leave_providers.dart';

class AvailabilityPage extends ConsumerWidget {
  final String entityId;
  final String entityName;

  const AvailabilityPage({
    super.key,
    required this.entityId,
    required this.entityName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leavesAsync = ref.watch(leavesByEntityProvider(entityId));
    final employeeAsync = ref.watch(employeeByIdProvider(entityId));

    final double width = MediaQuery.of(context).size.width;

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
                  onTap: () => context.go('/admin/dashboard'),
                  child: Text(
                    'Admin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                InkWell(
                  onTap: () => context.go('/admin/employees'),
                  child: Text(
                    'Employees',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text(
                  'Availability: $entityName',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Leave Management',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildSummaryGrid(leavesAsync, employeeAsync, width),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(
                '/admin/employees/$entityId/availability/apply?name=$entityName',
              ),
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
                'Mark Unavailability',
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
          return count == count.toInt().toDouble()
              ? count.toInt().toString()
              : count.toStringAsFixed(1);
        }

        return employeeAsync.when(
          data: (employee) {
            final carriedForward = (employee?.carriedForwardLeaves ?? 0);
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
        final sorted = List<Leave>.from(leaves)
          ..sort((a, b) => b.date.compareTo(a.date));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                    if (leave.status == LeaveStatus.pending ||
                        leave.status == LeaveStatus.cancelRequest)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _updateStatus(
                              context,
                              ref,
                              leave.id,
                              LeaveStatus.approved,
                            ),
                            icon: const Icon(
                              LucideIcons.checkCircle,
                              color: Colors.green,
                            ),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            onPressed: () => _updateStatus(
                              context,
                              ref,
                              leave.id,
                              LeaveStatus.rejected,
                            ),
                            icon: const Icon(
                              LucideIcons.xCircle,
                              color: Colors.red,
                            ),
                            tooltip: 'Reject',
                          ),
                        ],
                      )
                    else if (leave.status == LeaveStatus.approved)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _showConfirmDialog(
                          context,
                          'Delete Entry',
                          'Are you sure you want to remove this approved entry? This will restore availability.',
                          () => ref
                              .read(leaveServiceProvider)
                              .removeLeave(leave.id),
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

  void _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String leaveId,
    LeaveStatus status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('${status.name.toUpperCase()} Request'),
        content: Text('Are you sure you want to ${status.name} this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == LeaveStatus.approved
                  ? Colors.green
                  : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(leaveServiceProvider)
          .updateStatus(leaveId: leaveId, status: status);
    }
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
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
