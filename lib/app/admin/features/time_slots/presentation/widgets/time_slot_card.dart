import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/models/time_slot.dart';
import '/core/providers/time_slot_providers.dart';
import 'edit_time_slot_dialog.dart';

class TimeSlotCard extends ConsumerWidget {
  final TimeSlot slot;
  const TimeSlotCard({required this.slot, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: slot.isActive ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      color: slot.isActive ? Colors.white : Colors.red.withOpacity(0.02),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: slot.isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    slot.isActive ? 'ACTIVE' : 'ARCHIVED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: slot.isActive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  slot.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (val) => _handleAction(context, ref, val),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => [
                if (slot.isActive) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    height: 40,
                    child: Text('Edit & Re-version'),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    height: 40,
                    child: Text('Archive (Soft Delete)'),
                  ),
                ] else ...[
                  const PopupMenuItem(
                    value: 'unarchive',
                    height: 40,
                    child: Text('Restore (Unarchive)'),
                  ),
                ],
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
      case 'archive':
        _showConfirm(
          context,
          ref,
          'Archive',
          'This hides the slot but keeps history.',
          () {
            ref.read(timeSlotServiceProvider).archiveTimeSlot(slot.id);
          },
        );
        break;
      case 'unarchive':
        _showConfirm(
          context,
          ref,
          'Restore',
          'Make this slot active again?',
          () {
            ref.read(timeSlotServiceProvider).unarchiveTimeSlot(slot.id);
          },
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
      return DateFormat.jm().format(dt);
    } catch (_) {
      return time24h;
    }
  }
}
