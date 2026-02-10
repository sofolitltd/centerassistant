import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/service_rate.dart';
import '/core/providers/service_rate_providers.dart';
import '/core/providers/employee_providers.dart';

class EditServiceRateDialog extends ConsumerStatefulWidget {
  final ServiceRate rate;

  const EditServiceRateDialog({super.key, required this.rate});

  @override
  ConsumerState<EditServiceRateDialog> createState() =>
      _EditServiceRateDialogState();
}

class _EditServiceRateDialogState extends ConsumerState<EditServiceRateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rateController;
  late String _selectedType;
  late DateTime _effectiveDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.rate.hourlyRate.toStringAsFixed(0),
    );
    _selectedType = widget.rate.serviceType;
    _effectiveDate = widget.rate.effectiveDate;
    _endDate = widget.rate.endDate;
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(schedulableDepartmentsProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Service Rate',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Service Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                deptsAsync.when(
                  data: (depts) => DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: depts
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading services'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hourly Rate (BDT)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 1700',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator: (value) =>
                      (value == null || double.tryParse(value) == null)
                      ? 'Enter a valid amount'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Effective Date',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd MMM yyyy').format(_effectiveDate), style: const TextStyle(fontSize: 13)),
                                  const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End Date (Optional)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: _endDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () => setState(() => _endDate = null),
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endDate != null
                                        ? DateFormat('dd MMM yyyy').format(_endDate!)
                                        : 'Set End Date',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _endDate == null ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  if (_endDate == null)
                                    const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _handleSave,
                      child: const Text('Update Rate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _effectiveDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _effectiveDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final updatedRate = ServiceRate(
        id: widget.rate.id,
        serviceType: _selectedType,
        hourlyRate: double.parse(_rateController.text),
        effectiveDate: _effectiveDate,
        endDate: _endDate,
      );
      await ref.read(serviceRateServiceProvider).updateRate(updatedRate);
      if (mounted) Navigator.pop(context);
    }
  }
}
