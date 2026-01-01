import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/leave.dart';
import '/core/providers/leave_providers.dart';

class AvailabilityPage extends ConsumerStatefulWidget {
  final String entityId;
  final LeaveEntityType entityType;
  final String entityName;

  const AvailabilityPage({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.entityName,
  });

  @override
  ConsumerState<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends ConsumerState<AvailabilityPage> {
  // Start with an empty list for maximum flexibility
  final List<DateTime> _selectedDates = [];
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;

    // Using ref.watch with a provider to manage the stream state correctly
    final leavesAsync = ref.watch(leavesByEntityProvider(widget.entityId));

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final parentRoute = widget.entityType == LeaveEntityType.client
        ? 'Clients'
        : 'Employees';
    final parentPath = widget.entityType == LeaveEntityType.client
        ? '/admin/clients'
        : '/admin/employees';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability: ${widget.entityName}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _breadcrumbItem('Admin', () => context.go('/admin/layout')),
            _breadcrumbSeparator(),
            _breadcrumbItem(parentRoute, () => context.go(parentPath)),
            _breadcrumbSeparator(),
            Text('Availability', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _breadcrumbItem(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _breadcrumbSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
    );
  }

  Widget _buildAddSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark New Unavailability',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFieldTitle('Date(s)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
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
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final normalized = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
                        if (!_selectedDates.any(
                          (d) =>
                              d.year == normalized.year &&
                              d.month == normalized.month &&
                              d.day == normalized.day,
                        )) {
                          setState(() {
                            _selectedDates.add(normalized);
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            if (_selectedDates.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Please select at least one date',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            _buildFieldTitle('Reason'),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDates.isEmpty
                    ? null
                    : () async {
                        final service = ref.read(leaveServiceProvider);
                        for (final date in _selectedDates) {
                          await service.addLeave(
                            entityId: widget.entityId,
                            entityType: widget.entityType,
                            date: date,
                            reason: _reasonController.text.trim(),
                          );
                        }

                        _reasonController.clear();
                        setState(() {
                          _selectedDates.clear();
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unavailabilities marked successfully',
                              ),
                            ),
                          );
                        }
                      },
                child: const Text('Add Unavailability'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(AsyncValue<List<Leave>> leavesAsync) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marked Unavailabilities',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        leavesAsync.when(
          data: (leaves) {
            if (leaves.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No unavailabilities marked yet.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPast
                            ? Colors.grey.shade100
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_busy,
                        color: isPast
                            ? Colors.grey.shade500
                            : Colors.red.shade700,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      DateFormat('dd MMM, yyyy').format(leave.date),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isPast ? Colors.grey.shade600 : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        leave.reason?.isEmpty ?? true
                            ? 'No reason provided'
                            : leave.reason!,
                        style: TextStyle(
                          color: isPast
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteConfirm(context, leave.id),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, String leaveId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unavailability'),
        content: const Text('Are you sure you want to remove this mark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(leaveServiceProvider).removeLeave(leaveId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
