import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/schedule_template.dart';

class AddScheduleRecurringSection extends StatefulWidget {
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final List<String> selectedDays;
  final RecurrenceEndType endType;
  final DateTime? endDate;
  final int occurrences;

  // Pass callbacks to update parent state
  final Function(List<String>) onDaysChanged;
  final Function(RecurrenceEndType) onEndTypeChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(int) onOccurrencesChanged;

  const AddScheduleRecurringSection({
    super.key,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.selectedDays,
    required this.endType,
    this.endDate,
    required this.occurrences,
    required this.onDaysChanged,
    required this.onEndTypeChanged,
    required this.onEndDateChanged,
    required this.onOccurrencesChanged,
  });

  @override
  State<AddScheduleRecurringSection> createState() =>
      _AddScheduleRecurringSectionState();
}

class _AddScheduleRecurringSectionState
    extends State<AddScheduleRecurringSection> {
  final List<String> _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.repeat, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Repeat Weekly',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Schedule this session to repeat every week',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isRecurring,
                onChanged: widget.onRecurringChanged,
              ),
            ],
          ),
        ),

        if (widget.isRecurring) ...[
          const SizedBox(height: 24),
          const Text(
            'Repeat on',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = _dayNames[index];
              final isSelected = widget.selectedDays.contains(day);
              final label = day.substring(0, 1);

              return InkWell(
                onTap: () {
                  final newDays = List<String>.from(widget.selectedDays);
                  if (isSelected) {
                    if (newDays.length > 1) newDays.remove(day);
                  } else {
                    newDays.add(day);
                  }
                  widget.onDaysChanged(newDays);
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? Colors.blue
                      : Colors.grey.shade100,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ends',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          // End on Date
          RadioListTile<RecurrenceEndType>(
            value: RecurrenceEndType.onDate,
            groupValue: widget.endType,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Text('On Date', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          widget.endDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) widget.onEndDateChanged(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.endDate == null
                          ? 'Select Date'
                          : DateFormat('dd MMM, yyyy').format(widget.endDate!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onChanged: (v) => widget.onEndTypeChanged(v!),
          ),

          // End after Occurrences
          RadioListTile<RecurrenceEndType>(
            value: RecurrenceEndType.afterOccurrences,
            groupValue: widget.endType,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Text('After', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  height: 36,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v);
                      if (val != null) widget.onOccurrencesChanged(val);
                    },
                    controller: TextEditingController(
                      text: widget.occurrences.toString(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Sessions', style: TextStyle(fontSize: 14)),
              ],
            ),
            onChanged: (v) => widget.onEndTypeChanged(v!),
          ),
        ],
      ],
    );
  }
}
