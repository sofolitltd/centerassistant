import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final discountsAsync = ref
        .watch(clientDiscountsProvider(widget.client.id))
        .whenData((list) {
          if (_filter == 'Active') {
            return list.where((d) {
              final isEffective = !d.effectiveDate.isAfter(today);
              final isNotExpired =
                  d.endDate == null || !d.endDate!.isBefore(today);
              return isEffective && isNotExpired;
            }).toList();
          } else if (_filter == 'Upcoming') {
            return list.where((d) => d.effectiveDate.isAfter(today)).toList();
          } else if (_filter == 'Expired') {
            return list
                .where((d) => d.endDate != null && d.endDate!.isBefore(today))
                .toList();
          }
          return list; // 'All'
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: .symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              //
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    _buildFilterButton('Active'),
                    _buildFilterButton('Upcoming'),
                    _buildFilterButton('Expired'),
                    _buildFilterButton('All'),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Discount'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: discountsAsync.when(
            data: (discounts) {
              if (discounts.isEmpty) {
                return Center(child: Text('No $_filter discounts found.'));
              }

              // In 'All' view or others, maybe sort by effective date
              final sortedDiscounts = List<ClientDiscount>.from(discounts)
                ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

              return ListView.separated(
                itemCount: sortedDiscounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _DiscountCard(
                    discount: sortedDiscounts[index],
                    onEdit: () =>
                        _showEditDialog(context, sortedDiscounts[index]),
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
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _DiscountFormDialog(clientId: widget.client.id),
    );
  }

  void _showEditDialog(BuildContext context, ClientDiscount discount) {
    showDialog(
      context: context,
      builder: (context) =>
          _DiscountFormDialog(clientId: widget.client.id, discount: discount),
    );
  }
}

class _DiscountCard extends ConsumerWidget {
  final ClientDiscount discount;
  final VoidCallback onEdit;
  const _DiscountCard({required this.discount, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String status = 'ACTIVE';
    Color statusColor = Colors.green;

    if (discount.effectiveDate.isAfter(today)) {
      status = 'UPCOMING';
      statusColor = Colors.blue;
    } else if (discount.endDate != null && discount.endDate!.isBefore(today)) {
      status = 'EXPIRED';
      statusColor = Colors.red;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('MMM dd, yyyy').format(discount.effectiveDate)} - ${discount.endDate != null ? DateFormat('MMM dd, yyyy').format(discount.endDate!) : 'Present'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 16),
              onSelected: (val) async {
                if (val == 'edit') {
                  onEdit();
                } else if (val == 'delete') {
                  await ref
                      .read(clientDiscountServiceProvider)
                      .deleteDiscount(discount);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountFormDialog extends ConsumerStatefulWidget {
  final String clientId;
  final ClientDiscount? discount;
  const _DiscountFormDialog({required this.clientId, this.discount});

  @override
  ConsumerState<_DiscountFormDialog> createState() =>
      _DiscountFormDialogState();
}

class _DiscountFormDialogState extends ConsumerState<_DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  String? _selectedService;
  DateTime _effectiveDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.discount != null) {
      _discountController.text = widget.discount!.discountPerHour.toString();
      _selectedService = widget.discount!.serviceType;
      _effectiveDate = widget.discount!.effectiveDate;
      _endDate = widget.discount!.endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGlobalRates = ref.watch(activeServiceRatesProvider);

    return AlertDialog(
      title: Text(
        widget.discount == null
            ? 'Add Client Discount'
            : 'Edit Client Discount',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                  child: Text(
                    DateFormat('MMMM dd, yyyy').format(_effectiveDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _endDate ??
                        _effectiveDate.add(const Duration(days: 30)),
                    firstDate: _effectiveDate,
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _endDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _endDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _endDate == null
                        ? 'No End Date'
                        : DateFormat('MMMM dd, yyyy').format(_endDate!),
                  ),
                ),
              ),
            ],
          ),
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
              if (widget.discount == null) {
                await ref
                    .read(clientDiscountServiceProvider)
                    .addDiscount(
                      clientId: widget.clientId,
                      serviceType: _selectedService!,
                      discountPerHour: double.parse(_discountController.text),
                      effectiveDate: _effectiveDate,
                      endDate: _endDate,
                    );
              } else {
                await ref
                    .read(clientDiscountServiceProvider)
                    .updateDiscount(
                      widget.discount!.copyWith(
                        serviceType: _selectedService,
                        discountPerHour: double.parse(_discountController.text),
                        effectiveDate: _effectiveDate,
                        endDate: () => _endDate,
                      ),
                    );
              }
              if (mounted) Navigator.pop(context);
            }
          },
          child: Text(
            widget.discount == null ? 'Add Discount' : 'Update Discount',
          ),
        ),
      ],
    );
  }
}
