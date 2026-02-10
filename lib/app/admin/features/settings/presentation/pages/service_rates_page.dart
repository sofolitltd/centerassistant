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
  String _filter = 'Active'; // 'Active' or 'Archived'

  @override
  Widget build(BuildContext context) {
    final ratesAsync = _filter == 'Archived'
        ? ref
              .watch(allServiceRatesProvider)
              .whenData((rates) => rates.where((r) => !r.isActive).toList())
        : ref.watch(activeServiceRatesProvider);

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
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
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
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Service Charges',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 32),

              // Filters
              Row(
                children: [
                  _buildFilterButton('Active'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Archived'),
                ],
              ),

              //
              const SizedBox(height: 32),

              // Content
              ratesAsync.when(
                data: (rates) {
                  if (rates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('No $_filter service rates found.'),
                      ),
                    );
                  }

                  // Group by Effective Date
                  final grouped = <DateTime, List<ServiceRate>>{};
                  for (var rate in rates) {
                    final date = DateTime(
                      rate.effectiveDate.year,
                      rate.effectiveDate.month,
                      rate.effectiveDate.day,
                    );
                    grouped.putIfAbsent(date, () => []).add(rate);
                  }

                  final sortedDates = grouped.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 40),
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final currentRates = grouped[date]!;

                      // Sort by Service Type
                      currentRates.sort(
                        (a, b) => a.serviceType.compareTo(b.serviceType),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Effective from ${DateFormat('MMMM dd, yyyy').format(date)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MasonryGridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            itemCount: currentRates.length,
                            itemBuilder: (context, idx) {
                              final rate = currentRates[idx];
                              return ServiceRateCard(rate: rate);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
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

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddServiceRateDialog(),
    );
  }
}
