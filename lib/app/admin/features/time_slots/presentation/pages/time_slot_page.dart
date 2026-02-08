import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/time_slot.dart';
import '/core/providers/time_slot_providers.dart';
import '../widgets/add_time_slot_dialog.dart';
import '../widgets/time_slot_card.dart';

class TimeSlotPage extends ConsumerStatefulWidget {
  const TimeSlotPage({super.key});

  @override
  ConsumerState<TimeSlotPage> createState() => _TimeSlotPageState();
}

class _TimeSlotPageState extends ConsumerState<TimeSlotPage> {
  String _filter = 'Active'; // 'Active' or 'Archived'

  @override
  Widget build(BuildContext context) {
    final slotsAsync = _filter == 'Archived'
        ? ref
              .watch(allTimeSlotsProvider)
              .whenData((slots) => slots.where((s) => !s.isActive).toList())
        : ref.watch(timeSlotsProvider);

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

    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.go('/admin/dashboard'),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const Text(
                            'Settings',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const Text(
                            'Time Slots',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time Slots',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time Slot'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Filters
              Row(
                children: [
                  _buildFilterButton('Active'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Archived'),
                ],
              ),
              const SizedBox(height: 32),

              // Grid Content
              slotsAsync.when(
                data: (timeSlots) {
                  if (timeSlots.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('No $_filter time slots found.'),
                      ),
                    );
                  }

                  // Group by Effective Date
                  final grouped = <DateTime, List<TimeSlot>>{};
                  for (var slot in timeSlots) {
                    final date = DateTime(
                      slot.effectiveDate.year,
                      slot.effectiveDate.month,
                      slot.effectiveDate.day,
                    );
                    grouped.putIfAbsent(date, () => []).add(slot);
                  }

                  final sortedDates = grouped.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 40),
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final slots = grouped[date]!;

                      // Sort slots by startTime (24h HH:mm format)
                      slots.sort((a, b) => a.startTime.compareTo(b.startTime));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Effective from ${DateFormat('MMMM dd, yyyy').format(date)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MasonryGridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            itemCount: slots.length,
                            itemBuilder: (context, idx) {
                              final slot = slots[idx];
                              return TimeSlotCard(slot: slot);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTimeSlotDialog(),
    );
  }
}
