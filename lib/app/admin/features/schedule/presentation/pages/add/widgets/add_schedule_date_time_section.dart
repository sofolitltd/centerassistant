import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddScheduleDateTimeSection extends StatelessWidget {
  final DateTime selectedDate;
  final AsyncValue<List<dynamic>> timeSlotsAsync;
  final String? selectedTimeSlotId;
  final Function(DateTime)? onDateChanged;
  final Function(String?, dynamic)? onTimeSlotChanged;
  final String Function(String) formatTimeToAmPm;

  const AddScheduleDateTimeSection({
    super.key,
    required this.selectedDate,
    required this.timeSlotsAsync,
    required this.selectedTimeSlotId,
    this.onDateChanged,
    this.onTimeSlotChanged,
    required this.formatTimeToAmPm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        //
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onDateChanged == null
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          onDateChanged!(picked);
                        }
                      },
                child: InputDecorator(
                  decoration: _inputDecoration().copyWith(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 14,
                    ),
                    fillColor: onDateChanged == null
                        ? Colors.grey.shade100
                        : Colors.grey.shade50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                        style: TextStyle(
                          color: onDateChanged == null
                              ? Colors.black54
                              : Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: onDateChanged == null
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        //
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time Slot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              //
              timeSlotsAsync.when(
                data: (slots) {
                  final sortedSlots = List<dynamic>.from(slots)
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  return DropdownButtonFormField<String>(
                    initialValue: selectedTimeSlotId,
                    isExpanded: true,
                    hint: const Text('Select Slot'),
                    onChanged: onTimeSlotChanged == null
                        ? null
                        : (v) {
                            final slot = sortedSlots
                                .where((s) => s.id == v)
                                .firstOrNull;
                            onTimeSlotChanged!(v, slot);
                          },
                    items: sortedSlots
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              '${formatTimeToAmPm(s.startTime)} - ${formatTimeToAmPm(s.endTime)} (${s.label})',
                            ),
                          ),
                        )
                        .toList(),
                    decoration: _inputDecoration().copyWith(
                      fillColor: onTimeSlotChanged == null
                          ? Colors.grey.shade100
                          : Colors.grey.shade50,
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading time slots'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? label, String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
