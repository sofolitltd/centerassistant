import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/service_rate.dart';
import '/core/providers/service_rate_providers.dart';
import '../widgets/add_service_rate_dialog.dart';
import '../widgets/service_rate_card.dart';

class ServiceRatesPage extends ConsumerStatefulWidget {
  const ServiceRatesPage({super.key});

  @override
  ConsumerState<ServiceRatesPage> createState() => _ServiceRatesPageState();
}

class _ServiceRatesPageState extends ConsumerState<ServiceRatesPage> {
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(allServiceRatesProvider);
    final double width = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (width > 1100) {
      crossAxisCount = 4;
    } else if (width > 900) {
      crossAxisCount = 3;
    } else if (width > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/admin/dashboard'),
                          child: const Text(
                            'Admin',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Text(
                          'Settings',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Text(
                          'Service Charges',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Service Charges',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service Rate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters
            Container(
              padding: .all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildFilterButton('Active'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Upcoming'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Expired'),
                  const SizedBox(width: 8),
                  _buildFilterButton('All'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ratesAsync.when(
              data: (rates) {
                final filtered = _filterRates(rates, _filter);
                return _buildRateList(filtered, crossAxisCount);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<ServiceRate> _filterRates(List<ServiceRate> rates, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return rates.where((rate) {
      final start = DateTime(
        rate.effectiveDate.year,
        rate.effectiveDate.month,
        rate.effectiveDate.day,
      );

      switch (filter) {
        case 'Active':
          final isStarted = !start.isAfter(today);
          final isNotEnded =
              rate.endDate == null ||
              !DateTime(
                rate.endDate!.year,
                rate.endDate!.month,
                rate.endDate!.day,
              ).isBefore(today);
          return isStarted && isNotEnded;
        case 'Upcoming':
          return start.isAfter(today);
        case 'Expired':
          return rate.endDate != null &&
              DateTime(
                rate.endDate!.year,
                rate.endDate!.month,
                rate.endDate!.day,
              ).isBefore(today);
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildRateList(List<ServiceRate> rates, int crossAxisCount) {
    if (rates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 64),
          child: Column(
            children: [
              Icon(Icons.money_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No service charges found.'),
            ],
          ),
        ),
      );
    }

    final grouped = <DateTime, List<ServiceRate>>{};
    for (var rate in rates) {
      final date = DateTime(
        rate.effectiveDate.year,
        rate.effectiveDate.month,
        rate.effectiveDate.day,
      );
      grouped.putIfAbsent(date, () => []).add(rate);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 32),
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final currentRates = grouped[date]!;
        currentRates.sort((a, b) => a.serviceType.compareTo(b.serviceType));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date, currentRates.first.endDate),
            const SizedBox(height: 16),
            MasonryGridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: currentRates.length,
              itemBuilder: (context, idx) {
                return ServiceRateCard(rate: currentRates[idx]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime start, DateTime? end) {
    final formattedStart = DateFormat('MMMM dd, yyyy').format(start);
    String text = 'Effective from $formattedStart';
    if (end != null) {
      final formattedEnd = DateFormat('MMMM dd, yyyy').format(end);
      text = 'Effective: $formattedStart - $formattedEnd';
    }

    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddServiceRateDialog(),
    );
  }
}
