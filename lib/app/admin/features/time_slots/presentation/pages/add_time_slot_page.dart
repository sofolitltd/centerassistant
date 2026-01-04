import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/providers/time_slot_providers.dart';

class AddTimeSlotPage extends ConsumerStatefulWidget {
  const AddTimeSlotPage({super.key});

  @override
  ConsumerState<AddTimeSlotPage> createState() => _AddTimeSlotPageState();
}

class _AddTimeSlotPageState extends ConsumerState<AddTimeSlotPage> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children
                .expand((widget) => [widget, const SizedBox(height: 20)])
                .toList()
              ..removeLast(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand(
                (widget) => [
                  Expanded(child: widget),
                  const SizedBox(width: 16),
                ],
              )
              .toList()
            ..removeLast(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Time Slot',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/admin/dashboard'),
                  child: Text(
                    'Admin',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                InkWell(
                  onTap: () => context.go('/admin/time-slots'),
                  child: Text(
                    'Time Slots',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text(
                  'Add Time Slot',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitle('Label (e.g., Morning)'),
                      TextFormField(
                        controller: _labelController,
                        decoration: const InputDecoration(
                          hintText: 'Enter label',
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a label' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildResponsiveRow(
                        isMobile: isMobile,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldTitle('Start Time'),
                              InkWell(
                                onTap: () async {
                                  final pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (pickedTime != null) {
                                    setState(() => _startTime = pickedTime);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(),
                                  child: Text(
                                    _startTime == null
                                        ? 'Select Start Time'
                                        : _startTime!.format(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldTitle('End Time'),
                              InkWell(
                                onTap: () async {
                                  final pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (pickedTime != null) {
                                    setState(() => _endTime = pickedTime);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(),
                                  child: Text(
                                    _endTime == null
                                        ? 'Select End Time'
                                        : _endTime!.format(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => context.go('/admin/time-slots'),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate() &&
                                  _startTime != null &&
                                  _endTime != null) {
                                ref
                                    .read(timeSlotServiceProvider)
                                    .addTimeSlot(
                                      label: _labelController.text,
                                      startTime: _startTime!.format(context),
                                      endTime: _endTime!.format(context),
                                    );
                                context.go('/admin/time-slots');
                              } else if (_startTime == null ||
                                  _endTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select start and end times',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Add Time Slot'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
