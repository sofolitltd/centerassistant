import 'package:flutter/material.dart';

class OfficeClosedView extends StatelessWidget {
  final String reason;

  const OfficeClosedView({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 60, color: Colors.orange.shade200),
          const SizedBox(height: 12),
          Text(
            'Office Closed: $reason',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Scheduling is disabled for this date.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
