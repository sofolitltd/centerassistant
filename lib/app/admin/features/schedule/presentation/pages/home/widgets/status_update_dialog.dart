import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/session.dart';
import '/core/providers/session_providers.dart';

class StatusUpdateDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;

  const StatusUpdateDialog({
    super.key,
    required this.session,
    required this.timeSlotId,
  });

  @override
  ConsumerState<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends ConsumerState<StatusUpdateDialog> {
  late SessionStatus _selectedStatus;
  String _mode = 'this_only';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.session.status;
  }

  bool get _canConfirm =>
      _selectedStatus != widget.session.status || _mode != 'this_only';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Update Session Status', style: TextStyle(fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Status',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SessionStatus>(
              value: _selectedStatus,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: SessionStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Apply to',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text(
                'This session only',
                style: TextStyle(fontSize: 14),
              ),
              value: 'this_only',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
            RadioListTile<String>(
              title: const Text(
                'This and following',
                style: TextStyle(fontSize: 14),
              ),
              value: 'this_and_following',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
            RadioListTile<String>(
              title: const Text('All sessions', style: TextStyle(fontSize: 14)),
              value: 'all',
              groupValue: _mode,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _mode = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || !_canConfirm) ? null : _handleUpdate,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      final selectedDate = ref.read(selectedDateProvider);
      await ref
          .read(sessionServiceProvider)
          .updateSessionStatus(
            clientId: widget.session.clientDocId,
            timeSlotId: widget.timeSlotId,
            services: widget.session.services,
            newStatus: _selectedStatus,
            date: selectedDate,
            mode: _mode,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
