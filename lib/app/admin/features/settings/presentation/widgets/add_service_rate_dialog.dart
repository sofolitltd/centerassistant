import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/providers/employee_providers.dart';
import '/core/providers/service_rate_providers.dart';

class AddServiceRateDialog extends ConsumerStatefulWidget {
  const AddServiceRateDialog({super.key});

  @override
  ConsumerState<AddServiceRateDialog> createState() =>
      _AddServiceRateDialogState();
}

class _AddServiceRateDialogState extends ConsumerState<AddServiceRateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  String? _selectedType;
  DateTime _effectiveDate = DateTime.now();

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
                      'Add Service Rate',
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
                  data: (depts) {
                    final items = depts.toList();
                    if (_selectedType == null && items.isNotEmpty) {
                      _selectedType = items.first;
                    }
                    return ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: items
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedType = val!),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading services: $e'),
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
                      vertical: 12,
                    ),
                  ),
                  validator: (value) =>
                      (value == null || double.tryParse(value) == null)
                      ? 'Enter a valid amount'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Effective Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(_effectiveDate)),
                        const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
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
                      child: const Text('Add Service Rate'),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _effectiveDate = picked);
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      await ref
          .read(serviceRateServiceProvider)
          .addRate(
            serviceType: _selectedType!,
            hourlyRate: double.parse(_rateController.text),
            effectiveDate: _effectiveDate,
          );
      if (mounted) Navigator.pop(context);
    }
  }
}
