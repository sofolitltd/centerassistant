import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddScheduleFooter extends StatelessWidget {
  final bool isSaveEnabled;
  final VoidCallback onSave;

  const AddScheduleFooter({
    super.key,
    required this.isSaveEnabled,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: isSaveEnabled ? onSave : null,
          child: const Text('Save Schedule'),
        ),
      ],
    );
  }
}
