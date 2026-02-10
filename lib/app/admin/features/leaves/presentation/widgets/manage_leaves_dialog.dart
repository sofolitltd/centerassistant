import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/models/leave.dart';
import '/core/providers/leave_providers.dart';

class ManageLeavesDialog extends ConsumerStatefulWidget {
  final String entityId;
  final String entityName;

  const ManageLeavesDialog({
    super.key,
    required this.entityId,
    required this.entityName,
  });

  @override
  ConsumerState<ManageLeavesDialog> createState() => _ManageLeavesDialogState();
}

class _ManageLeavesDialogState extends ConsumerState<ManageLeavesDialog> {
  DateTime _selectedDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref
        .watch(leaveRepositoryProvider)
        .getLeavesByEntity(widget.entityId);

    return AlertDialog(
      title: Text('Manage Leaves: ${widget.entityName}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Leave Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mark New Unavailability',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null && mounted) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                              ),
                              child: Text(
                                DateFormat(
                                  'dd MMM, yyyy',
                                ).format(_selectedDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason (Optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(leaveServiceProvider)
                              .addLeave(
                                employeeId: widget.entityId,
                                date: _selectedDate,
                                reason: _reasonController.text.trim(),
                              );
                          _reasonController.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Leave added successfully'),
                              ),
                            );
                          }
                        },
                        child: const Text('Add Leave'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Existing Leaves',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Leaves List
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Leave>>(
                stream: leavesAsync,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final leaves = snapshot.data ?? [];
                  if (leaves.isEmpty) {
                    return const Center(child: Text('No leaves marked yet.'));
                  }
                  return ListView.builder(
                    itemCount: leaves.length,
                    itemBuilder: (context, index) {
                      final leave = leaves[index];
                      return ListTile(
                        title: Text(
                          DateFormat('dd MMM, yyyy').format(leave.date),
                        ),
                        subtitle: Text(leave.reason ?? 'No reason provided'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => ref
                              .read(leaveServiceProvider)
                              .removeLeave(leave.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
