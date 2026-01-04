import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '/core/models/time_slot.dart';
import '/core/providers/time_slot_providers.dart';

class TimeSlotPage extends ConsumerWidget {
  const TimeSlotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final double width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (width > 1100) {
      crossAxisCount = 4;
    } else if (width > 900) {
      crossAxisCount = 3;
    } else if (width > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    final bool isMobile = width < 600;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => context.go('/admin/dashboard'),
                              child: Text(
                                'Admin',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey,
                            ),
                            Text(
                              'Time Slots',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Time Slots',
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/admin/time-slots/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Time Slot'),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/time-slots/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Time Slot'),
                ),
              ],
              const SizedBox(height: 24),
              timeSlotsAsync.when(
                data: (timeSlots) {
                  if (timeSlots.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('No time slots found. Add one!'),
                      ),
                    );
                  }
                  return MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = timeSlots[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 40,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    timeSlot.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${timeSlot.startTime} - ${timeSlot.endTime}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                color: Colors.white,
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditTimeSlotDialog(
                                      context,
                                      ref,
                                      timeSlot,
                                    );
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmDialog(
                                      context,
                                      ref,
                                      timeSlot,
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit, size: 18),
                                      title: Text('Edit'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    TimeSlot timeSlot,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: Text('Are you sure you want to delete ${timeSlot.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(timeSlotServiceProvider).deleteTimeSlot(timeSlot.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  void _showEditTimeSlotDialog(
    BuildContext context,
    WidgetRef ref,
    TimeSlot timeSlot,
  ) {
    final labelController = TextEditingController(text: timeSlot.label);
    String startTime = timeSlot.startTime;
    String endTime = timeSlot.endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            content: Container(
              constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Time Slot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldTitle('Label'),
                        TextField(
                          controller: labelController,
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldTitle('Start Time'),
                        InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  _parseTime(startTime) ?? TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(
                                () => startTime = pickedTime.format(context),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Text(startTime),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldTitle('End Time'),
                        InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  _parseTime(endTime) ?? TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(
                                () => endTime = pickedTime.format(context),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Text(endTime),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updatedSlot = TimeSlot(
                    id: timeSlot.id,
                    label: labelController.text,
                    startTime: startTime,
                    endTime: endTime,
                  );
                  ref.read(timeSlotServiceProvider).updateTimeSlot(updatedSlot);
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      int hour = int.parse(parts[0]);
      final minuteAndAmPm = parts[1].split(' ');
      int minute = int.parse(minuteAndAmPm[0]);
      if (minuteAndAmPm.length == 2) {
        final amPm = minuteAndAmPm[1].toUpperCase();
        if (amPm == 'PM' && hour < 12) hour += 12;
        if (amPm == 'AM' && hour == 12) hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
}
