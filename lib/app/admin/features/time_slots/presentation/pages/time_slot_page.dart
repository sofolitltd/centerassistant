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
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(allTimeSlotsProvider);
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
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
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
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        InkWell(
                          onTap: () => context.go('/admin/dashboard'),
                          child: const Text(
                            'Dashboard',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Text(
                          'Time Slots',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time Slots',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
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
            const SizedBox(height: 24),

            // Filters (Custom Tabs)
            Container(
              padding: .all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildFilterButton('Active'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Upcoming'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Expired'),
                  const SizedBox(width: 8),
                  _buildFilterButton('All'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            slotsAsync.when(
              data: (timeSlots) {
                final filtered = _filterSlots(timeSlots, _filter);
                return _buildSlotList(filtered, crossAxisCount);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
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
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
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

  List<TimeSlot> _filterSlots(List<TimeSlot> slots, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return slots.where((slot) {
      final start = DateTime(
        slot.effectiveDate.year,
        slot.effectiveDate.month,
        slot.effectiveDate.day,
      );

      switch (filter) {
        case 'Active':
          final isStarted = !start.isAfter(today);
          final isNotEnded =
              slot.effectiveEndDate == null ||
              !DateTime(
                slot.effectiveEndDate!.year,
                slot.effectiveEndDate!.month,
                slot.effectiveEndDate!.day,
              ).isBefore(today);
          return isStarted && isNotEnded;
        case 'Upcoming':
          return start.isAfter(today);
        case 'Expired':
          return slot.effectiveEndDate != null &&
              DateTime(
                slot.effectiveEndDate!.year,
                slot.effectiveEndDate!.month,
                slot.effectiveEndDate!.day,
              ).isBefore(today);
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildSlotList(List<TimeSlot> timeSlots, int crossAxisCount) {
    if (timeSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 64),
          child: Column(
            children: [
              //
              Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
              SizedBox(height: 16),

              //
              Text('No time slots found.'),
            ],
          ),
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

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 32),
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final slots = grouped[date]!;
        slots.sort((a, b) => a.startTime.compareTo(b.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date, slots.first.effectiveEndDate),
            const SizedBox(height: 16),
            MasonryGridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: slots.length,
              itemBuilder: (context, idx) {
                return TimeSlotCard(slot: slots[idx]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime start, DateTime? end) {
    final formattedStart = DateFormat('MMMM dd, yyyy').format(start);
    String text = 'Effective from $formattedStart';
    if (end != null) {
      final formattedEnd = DateFormat('MMMM dd, yyyy').format(end);
      text = 'Effective: $formattedStart - $formattedEnd';
    }

    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
        IconButton(
          icon: const Icon(Icons.copy_all, size: 18),
          tooltip: 'Batch Duplicate slots from this period',
          onPressed: () => _batchDuplicate(start, end),
        ),
      ],
    );
  }

  void _batchDuplicate(DateTime start, DateTime? end) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch Duplicate feature coming soon!')),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTimeSlotDialog(),
    );
  }
}
