import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/providers/billing_providers.dart';

class BillingMonthNavigator extends ConsumerWidget {
  const BillingMonthNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBillingMonthProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          //
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth).toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            constraints: BoxConstraints(),
            padding: .zero,
            onPressed: () =>
                ref.read(selectedBillingMonthProvider.notifier).previousMonth(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            padding: .zero,
            constraints: BoxConstraints(),
            onPressed: () =>
                ref.read(selectedBillingMonthProvider.notifier).nextMonth(),
          ),
        ],
      ),
    );
  }
}
