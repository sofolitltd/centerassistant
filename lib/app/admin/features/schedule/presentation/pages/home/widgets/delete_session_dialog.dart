import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/providers/session_providers.dart';

class DeleteSessionDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;

  const DeleteSessionDialog({
    super.key,
    required this.session,
    required this.timeSlotId,
  });

  @override
  ConsumerState<DeleteSessionDialog> createState() =>
      _DeleteSessionDialogState();
}

class _DeleteSessionDialogState extends ConsumerState<DeleteSessionDialog> {
  String _mode = 'this_only';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Delete Session', style: TextStyle(fontSize: 18)),
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
              'Which sessions would you like to permanently delete?',
              style: TextStyle(fontSize: 14),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => _HardDeleteConfirmDialog(
                      session: widget.session,
                      timeSlotId: widget.timeSlotId,
                      mode: _mode,
                    ),
                  );
                },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _HardDeleteConfirmDialog extends ConsumerStatefulWidget {
  final SessionCardData session;
  final String timeSlotId;
  final String mode;

  const _HardDeleteConfirmDialog({
    required this.session,
    required this.timeSlotId,
    required this.mode,
  });

  @override
  ConsumerState<_HardDeleteConfirmDialog> createState() =>
      _HardDeleteConfirmDialogState();
}

class _HardDeleteConfirmDialogState
    extends ConsumerState<_HardDeleteConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    String modeText = '';
    switch (widget.mode) {
      case 'this_only':
        modeText = 'this specific session';
        break;
      case 'this_and_following':
        modeText = 'this and all following sessions';
        break;
      case 'all':
        modeText = 'ALL sessions and the template rule';
        break;
    }

    return AlertDialog(
      title: const Text('Confirm Permanent Deletion'),
      constraints: const BoxConstraints(maxWidth: 400),
      content: Text(
        'Are you sure you want to permanently delete $modeText? '
        'This will clean up Firestore and cannot be undone. '
        '${widget.mode == 'all' ? '\n\nWARNING: This will also remove the recurring rule from the schedule template.' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _handleHardDelete,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete Forever'),
        ),
      ],
    );
  }

  Future<void> _handleHardDelete() async {
    setState(() => _isLoading = true);
    try {
      final selectedDate = ref.read(selectedDateProvider);
      await ref
          .read(sessionServiceProvider)
          .hardDeleteSession(
            clientId: widget.session.clientDocId,
            timeSlotId: widget.timeSlotId,
            date: selectedDate,
            mode: widget.mode,
          );
      if (mounted) {
        // Pop the confirmation dialog
        Navigator.pop(context);
        // Pop the delete options dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permanently deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
