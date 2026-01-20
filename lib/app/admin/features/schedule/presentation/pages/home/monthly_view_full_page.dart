import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monthly_view.dart';
import 'widgets/schedule_filter_bar.dart';

class MonthlyViewFullPage extends ConsumerWidget {
  const MonthlyViewFullPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Monthly Schedule Full View')),
      body: Column(
        children: [
          const ScheduleFilterBar(),
          const Expanded(child: MonthlyView()),
        ],
      ),
    );
  }
}
