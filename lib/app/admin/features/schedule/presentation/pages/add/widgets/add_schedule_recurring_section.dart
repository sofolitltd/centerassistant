import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/schedule_template.dart';
import '/core/providers/office_settings_providers.dart';

class AddScheduleRecurringSection extends ConsumerStatefulWidget {
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final List<String> selectedDays;
  final RecurrenceEndType endType;
  final DateTime? endDate;
  final int occurrences;

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
  ConsumerState<AddScheduleRecurringSection> createState() =>
      _AddScheduleRecurringSectionState();
}

class _AddScheduleRecurringSectionState
    extends ConsumerState<AddScheduleRecurringSection> {
  final List<String> _allDays = [
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
    final settingsAsync = ref.watch(officeSettingsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                activeThumbColor: Colors.blue,
                value: widget.isRecurring,
                onChanged: widget.onRecurringChanged,
              ),
            ],
          ),
          if (widget.isRecurring) ...[
            const SizedBox(height: 8),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            const Text(
              'Repeat on',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            settingsAsync.when(
              data: (settings) {
                final workingDays = _allDays
                    .where((day) => !settings.weeklyOffDays.contains(day))
                    .toList();

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: workingDays.map((day) {
                    final isSelected = widget.selectedDays.contains(day);
                    final label = day.substring(0, 3);

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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                        ),
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
                  }).toList(),
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (e, _) => Text('Error loading days: $e'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Ends',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
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
                            : DateFormat(
                                'dd MMM, yyyy',
                              ).format(widget.endDate!),
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
      ),
    );
  }
}
