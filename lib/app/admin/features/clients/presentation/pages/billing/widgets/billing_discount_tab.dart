import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/models/client_discount.dart';
import '/core/providers/client_discount_providers.dart';
import '/core/providers/service_rate_providers.dart';

class BillingDiscountTab extends ConsumerStatefulWidget {
  final Client client;
  const BillingDiscountTab({required this.client, super.key});

  @override
  ConsumerState<BillingDiscountTab> createState() => _BillingDiscountTabState();
}

class _BillingDiscountTabState extends ConsumerState<BillingDiscountTab> {
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) {
    final discountsAsync = _filter == 'Archived'
        ? ref
              .watch(clientDiscountsProvider(widget.client.id))
              .whenData((list) => list.where((d) => !d.isActive).toList())
        : ref.watch(activeClientDiscountsProvider(widget.client.id));

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildFilterButton('Active'),
                const SizedBox(width: 8),
                _buildFilterButton('Archived'),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Discount'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: discountsAsync.when(
            data: (discounts) {
              if (discounts.isEmpty) {
                return Center(child: Text('No $_filter discounts found.'));
              }

              final grouped = <DateTime, List<ClientDiscount>>{};
              for (var d in discounts) {
                final date = DateTime(
                  d.effectiveDate.year,
                  d.effectiveDate.month,
                  d.effectiveDate.day,
                );
                grouped.putIfAbsent(date, () => []).add(d);
              }

              final sortedDates = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.separated(
                itemCount: sortedDates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 32),
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final list = grouped[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Effective from ${DateFormat('MMM dd, yyyy').format(date)}',
                            style: const TextStyle(
                              fontSize: 13,
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
                        crossAxisCount: MediaQuery.of(context).size.width > 900
                            ? 3
                            : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: list.length,
                        itemBuilder: (context, idx) =>
                            _DiscountCard(discount: list[idx]),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _filter == label;
    return InkWell(
      onTap: () => setState(() => _filter = label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(50),
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddClientDiscountDialog(clientId: widget.client.id),
    );
  }
}

class _DiscountCard extends ConsumerWidget {
  final ClientDiscount discount;
  const _DiscountCard({required this.discount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: discount.isActive ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      color: discount.isActive ? Colors.white : Colors.red.withOpacity(0.01),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: discount.isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    discount.isActive ? 'ACTIVE' : 'ARCHIVED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: discount.isActive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  discount.serviceType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '- ৳${discount.discountPerHour.toStringAsFixed(0)} / hour',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discount applied to base rate',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 16),
              onSelected: (val) async {
                if (val == 'toggle') {
                  await ref
                      .read(clientDiscountServiceProvider)
                      .toggleDiscountStatus(discount);
                } else if (val == 'delete') {
                  await ref
                      .read(clientDiscountServiceProvider)
                      .deleteDiscount(discount);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(discount.isActive ? 'Archive' : 'Restore'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddClientDiscountDialog extends ConsumerStatefulWidget {
  final String clientId;
  const _AddClientDiscountDialog({required this.clientId});

  @override
  ConsumerState<_AddClientDiscountDialog> createState() =>
      _AddClientDiscountDialogState();
}

class _AddClientDiscountDialogState
    extends ConsumerState<_AddClientDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  String? _selectedService;
  DateTime _effectiveDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final activeGlobalRates = ref.watch(activeServiceRatesProvider);

    return AlertDialog(
      title: const Text('Add Client Discount'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            activeGlobalRates.when(
              data: (rates) => DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  border: OutlineInputBorder(),
                ),
                items: rates
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.serviceType,
                        child: Text(r.serviceType),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedService = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading services'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount per Hour (Tk)',
                border: OutlineInputBorder(),
                prefixText: '৳ ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _effectiveDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _effectiveDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Effective Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(DateFormat('MMMM dd, yyyy').format(_effectiveDate)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && _selectedService != null) {
              await ref
                  .read(clientDiscountServiceProvider)
                  .addDiscount(
                    clientId: widget.clientId,
                    serviceType: _selectedService!,
                    discountPerHour: double.parse(_discountController.text),
                    effectiveDate: _effectiveDate,
                  );
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Add Discount'),
        ),
      ],
    );
  }
}
