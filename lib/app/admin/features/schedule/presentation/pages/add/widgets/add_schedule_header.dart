import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddScheduleHeader extends StatelessWidget {
  final String title;
  const AddScheduleHeader({super.key, this.title = 'Add Schedule'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: () => context.go('/admin/dashboard'),
              child: const Text('Admin', style: TextStyle(color: Colors.grey)),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              onTap: () => context.go('/admin/schedule'),
              child: const Text(
                'Schedule',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            Text(title == 'Add Schedule' ? 'New' : 'Edit'),
          ],
        ),
      ],
    );
  }
}
