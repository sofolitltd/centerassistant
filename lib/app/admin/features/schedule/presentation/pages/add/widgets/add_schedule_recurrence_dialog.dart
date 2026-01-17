import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/core/models/schedule_template.dart';

class AddScheduleRecurrenceDialog extends StatefulWidget {
  final int initialInterval;
  final RecurrenceFrequency initialFrequency;
  final List<String> initialSelectedDays;
  final RecurrenceEndType initialEndType;
  final DateTime? initialEndDate;
  final int initialOccurrences;

  const AddScheduleRecurrenceDialog({
    super.key,
    required this.initialInterval,
    required this.initialFrequency,
    required this.initialSelectedDays,
    required this.initialEndType,
    this.initialEndDate,
    required this.initialOccurrences,
  });

  @override
  State<AddScheduleRecurrenceDialog> createState() =>
      _AddScheduleRecurrenceDialogState();
}

class _AddScheduleRecurrenceDialogState
    extends State<AddScheduleRecurrenceDialog> {
  late int _interval;
  late RecurrenceFrequency _frequency;
  late List<String> _selectedDays;
  late RecurrenceEndType _endType;
  DateTime? _endDate;
  late int _occurrences;

  @override
  void initState() {
    super.initState();
    _interval = widget.initialInterval;
    _frequency = widget.initialFrequency;
    _selectedDays = List.from(widget.initialSelectedDays);
    _endType = widget.initialEndType == RecurrenceEndType.onDate
        ? RecurrenceEndType.onDate
        : widget.initialEndType;
    _endDate = widget.initialEndDate;
    _occurrences = widget.initialOccurrences;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Custom Repeat',
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 400),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Repeat every'),
                const SizedBox(width: 16),
                SizedBox(
                  width: 50,
                  child: TextFormField(
                    initialValue: _interval.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _interval = int.tryParse(v) ?? 1),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF1F3F4),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<RecurrenceFrequency>(
                  value: _frequency,
                  onChanged: (v) => setState(() => _frequency = v!),
                  items:
                      [
                            RecurrenceFrequency.daily,
                            RecurrenceFrequency.weekly,
                            RecurrenceFrequency.monthly,
                          ]
                          .map(
                            (f) =>
                                DropdownMenuItem(value: f, child: Text(f.name)),
                          )
                          .toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_frequency == RecurrenceFrequency.weekly) ...[
              const Text(
                'Repeat on',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .asMap()
                    .entries
                    .map((entry) {
                      final dayNames = [
                        'Sunday',
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                      ];
                      final dayName = dayNames[entry.key];
                      final isSelected = _selectedDays.contains(dayName);
                      return InkWell(
                        onTap: () => setState(() {
                          if (isSelected) {
                            if (_selectedDays.length > 1) {
                              _selectedDays.remove(dayName);
                            }
                          } else {
                            _selectedDays.add(dayName);
                          }
                        }),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected
                              ? const Color(0xFF1A73E8)
                              : const Color(0xFFF1F3F4),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Ends', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _buildEndOption(
              RecurrenceEndType.onDate,
              'On',
              trailing: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _endDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _endDate == null
                        ? 'Select Date'
                        : DateFormat('MMM d, yyyy').format(_endDate!),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildEndOption(
              RecurrenceEndType.afterOccurrences,
              'After',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue: _occurrences.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setState(() => _occurrences = int.tryParse(v) ?? 1),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF1F3F4),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Sessions'),
                ],
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
          onPressed: () {
            Navigator.pop(context, {
              'interval': _interval,
              'frequency': _frequency,
              'selectedDays': _selectedDays,
              'endType': _endType,
              'endDate': _endDate,
              'occurrences': _occurrences,
            });
          },
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildEndOption(
    RecurrenceEndType type,
    String label, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Radio<RecurrenceEndType>(
          value: type,
          groupValue: _endType,
          onChanged: (v) => setState(() => _endType = v!),
        ),
        SizedBox(width: 60, child: Text(label)),
        if (trailing != null) Expanded(child: trailing),
      ],
    );
  }
}
