import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/providers/session_providers.dart';
import '../schedule_all_page.dart';

class ScheduleFilterBar extends ConsumerWidget {
  const ScheduleFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(plannerViewNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref
                          .read(selectedDateProvider.notifier)
                          .setDate(DateTime.now()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        side: const BorderSide(color: Colors.blueGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.chevron_left, size: 24),
                      onPressed: () =>
                          _navigateDate(ref, selectedDate, view, -1),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.chevron_right, size: 24),
                      onPressed: () =>
                          _navigateDate(ref, selectedDate, view, 1),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatToolbarDate(selectedDate, view),
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isMobile) const SizedBox(height: 12),
                _buildViewMenu(ref, view),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewMenu(WidgetRef ref, PlannerView currentView) {
    return Row(
      children: [
        _ViewMenuButton(
          label: 'Day',
          isSelected: currentView == PlannerView.daily,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.daily),
        ),
        const SizedBox(width: 4),
        _ViewMenuButton(
          label: 'Week',
          isSelected: currentView == PlannerView.weekly,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.weekly),
        ),
        const SizedBox(width: 4),
        _ViewMenuButton(
          label: 'Month',
          isSelected: currentView == PlannerView.monthly,
          onTap: () => ref
              .read(plannerViewNotifierProvider.notifier)
              .setView(PlannerView.monthly),
        ),
      ],
    );
  }

  void _navigateDate(
    WidgetRef ref,
    DateTime current,
    PlannerView view,
    int delta,
  ) {
    DateTime next;
    if (view == PlannerView.daily) {
      next = current.add(Duration(days: delta));
    } else if (view == PlannerView.weekly) {
      next = current.add(Duration(days: delta * 7));
    } else {
      next = DateTime(current.year, current.month + delta, 1);
    }
    ref.read(selectedDateProvider.notifier).setDate(next);
  }

  String _formatToolbarDate(DateTime date, PlannerView view) {
    if (view == PlannerView.monthly) {
      return DateFormat('MMMM yyyy').format(date);
    }
    if (view == PlannerView.daily) {
      return DateFormat('EEEE, MMMM dd, yyyy').format(date);
    }
    final start = date.subtract(Duration(days: date.weekday % 7));
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('MMM dd').format(start)} – ${DateFormat('MMM dd, yyyy').format(end)}';
  }
}

class _ViewMenuButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewMenuButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
