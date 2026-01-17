import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/service_rate.dart';
import '/core/providers/service_rate_providers.dart';

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

  final List<String> _serviceTypes = ['ABA', 'SLT', 'OT', 'PT'];

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.rate.hourlyRate.toStringAsFixed(0),
    );
    _selectedType = widget.rate.serviceType;
    _effectiveDate = widget.rate.effectiveDate;
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: _serviceTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
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
                        vertical: 8,
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
    if (_formKey.currentState!.validate()) {
      final updatedRate = ServiceRate(
        id: widget.rate.id,
        serviceType: _selectedType,
        hourlyRate: double.parse(_rateController.text),
        effectiveDate: _effectiveDate,
        isActive: widget.rate.isActive,
      );
      await ref.read(serviceRateServiceProvider).updateRate(updatedRate);
      if (mounted) Navigator.pop(context);
    }
  }
}
