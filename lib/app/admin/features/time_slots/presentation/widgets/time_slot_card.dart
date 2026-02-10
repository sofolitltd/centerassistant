import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/models/time_slot.dart';
import '/core/providers/time_slot_providers.dart';
import 'add_time_slot_dialog.dart';
import 'edit_time_slot_dialog.dart';

class TimeSlotCard extends ConsumerWidget {
  final TimeSlot slot;
  const TimeSlotCard({required this.slot, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final effectiveStart = DateTime(
      slot.effectiveDate.year,
      slot.effectiveDate.month,
      slot.effectiveDate.day,
    );

    final isUpcoming = effectiveStart.isAfter(today);
    final isExpired =
        slot.effectiveEndDate != null &&
        DateTime(
          slot.effectiveEndDate!.year,
          slot.effectiveEndDate!.month,
          slot.effectiveEndDate!.day,
        ).isBefore(today);

    final isActive = !isUpcoming && !isExpired;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isExpired
              ? Colors.red.shade100
              : isUpcoming
              ? Colors.blue.shade100
              : Colors.green.shade100,
        ),
      ),
      color: isExpired
          ? Colors.red.withOpacity(0.02)
          : isUpcoming
          ? Colors.blue.withOpacity(0.02)
          : Colors.green.withOpacity(0.01),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        slot.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isExpired)
                      const _StatusBadge(label: 'EXPIRED', color: Colors.red)
                    else if (isUpcoming)
                      const _StatusBadge(label: 'UPCOMING', color: Colors.blue)
                    else if (isActive)
                      const _StatusBadge(label: 'ACTIVE', color: Colors.green),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_format(slot.startTime)} - ${_format(slot.endTime)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (val) => _handleAction(context, ref, val),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  height: 40,
                  child: Text('Edit Slot'),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  height: 40,
                  child: Text('Duplicate Slot'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  height: 40,
                  child: Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => EditTimeSlotDialog(timeSlot: slot),
        );
        break;
      case 'duplicate':
        showDialog(
          context: context,
          builder: (context) => AddTimeSlotDialog(initialSlot: slot),
        );
        break;
      case 'delete':
        _showConfirm(
          context,
          ref,
          'Permanent Delete',
          'Warning: This may break historical records!',
          () {
            ref
                .read(timeSlotServiceProvider)
                .deleteTimeSlotPermanently(slot.id);
          },
          isDanger: true,
        );
        break;
    }
  }

  void _showConfirm(
    BuildContext context,
    WidgetRef ref,
    String title,
    String msg,
    VoidCallback onConfirm, {
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : null,
              foregroundColor: isDanger ? Colors.white : null,
            ),
            child: Text(title),
          ),
        ],
      ),
    );
  }

  String _format(String time24h) {
    try {
      final parts = time24h.split(':');
      final dt = DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      // 'hh' forces two digits (03), 'mm' is minutes, 'a' is AM/PM marker
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time24h;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
