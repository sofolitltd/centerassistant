import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client.dart';
import '/core/models/employee.dart';
import '/core/models/session.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import '/core/providers/time_slot_providers.dart';
import '../add_schedule_utils.dart';

class AddScheduleServiceDialog extends ConsumerStatefulWidget {
  final String? selectedTimeSlotId;
  final String? initialStartTime;
  final String? initialEndTime;
  final Employee? initialEmployee;
  final Client? selectedClient;
  final ServiceDetail? initialService;

  const AddScheduleServiceDialog({
    super.key,
    required this.selectedTimeSlotId,
    this.initialStartTime,
    this.initialEndTime,
    this.initialEmployee,
    this.selectedClient,
    this.initialService,
  });

  @override
  ConsumerState<AddScheduleServiceDialog> createState() =>
      _AddScheduleServiceDialogState();
}

class _AddScheduleServiceDialogState
    extends ConsumerState<AddScheduleServiceDialog> {
  Employee? _employee;
  String? _serviceType;
  String? _startTime;
  String? _endTime;
  SessionType _sessionType = SessionType.regular;
  bool _isInclusive = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialService != null) {
      final s = widget.initialService!;
      _startTime = s.startTime;
      _endTime = s.endTime;
      _serviceType = s.type;
      _sessionType = s.sessionType;
      _isInclusive = s.isInclusive;
      // Note: _employee is set via widget.initialEmployee in the parent call
      _employee = widget.initialEmployee;
    } else {
      _startTime = widget.initialStartTime;
      _endTime = widget.initialEndTime;
      _employee = widget.initialEmployee;
      if (_employee != null) {
        _serviceType = _employee!.department;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final deptsAsync = ref.watch(schedulableDepartmentsProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final scheduleAsync = ref.watch(scheduleViewProvider);

    final slots = timeSlotsAsync.value ?? [];
    final currentSlot = slots
        .where((s) => s.id == widget.selectedTimeSlotId)
        .firstOrNull;

    List<String> startTimes = [];
    List<String> endTimes = [];

    if (currentSlot != null) {
      startTimes = AddScheduleUtils.generateTimeOptions(
        currentSlot.startTime,
        currentSlot.endTime,
      );
      if (_startTime != null) {
        endTimes = AddScheduleUtils.generateTimeOptions(
          _startTime!,
          currentSlot.endTime,
          includeStart: false,
        );
      }
    }

    final bool isEdit = widget.initialService != null;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isEdit ? 'Edit Service' : 'Add Service'),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ButtonTheme(
          alignedDropdown: true,
          child: SizedBox(
            width: 400,
            child: Column(
              spacing: 2,
              mainAxisSize: MainAxisSize.min,
              children: [
                //
                employeesAsync.when(
                  data: (employees) => deptsAsync.when(
                    data: (depts) {
                      // 1. Filter the employees
                      final available = employees.where((e) {
                        final bool matchesDept =
                            depts.contains(e.department) &&
                            (_serviceType == null ||
                                e.department == _serviceType);

                        if (!matchesDept) return false;

                        // If it's edit mode, don't filter out the current employee
                        if (isEdit &&
                            e.id == widget.initialService?.employeeId) {
                          return true;
                        }

                        final busyTherapists =
                            scheduleAsync
                                .value
                                ?.sessionsByTimeSlot[widget.selectedTimeSlotId]
                                ?.expand((session) => session.services)
                                .map((service) => service.employeeId)
                                .toSet() ??
                            {};

                        return !busyTherapists.contains(e.id);
                      }).toList();

                      // 2. Sort A-Z by name
                      available.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );

                      // 3. Searchable Dropdown
                      return DropdownSearch<Employee>(
                        items: (filter, loadProps) => available,
                        itemAsString: (Employee e) => e.name,
                        selectedItem: _employee,
                        compareFn: (a, b) => a.id == b.id,
                        onChanged: (e) {
                          setState(() {
                            _employee = e;
                            if (e != null) {
                              _serviceType = e.department;
                            }
                          });
                        },
                        decoratorProps: DropDownDecoratorProps(
                          decoration: _inputDecoration(label: 'Therapist'),
                        ),
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          fit: FlexFit.loose,
                          constraints: BoxConstraints(maxHeight: 400),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search therapist...',
                              prefixIcon: Icon(Icons.search, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),

                const SizedBox(height: 16),
                //
                deptsAsync.when(
                  data: (depts) {
                    final items = depts.toList()..sort();

                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: depts.contains(_serviceType) ? _serviceType : null,
                      hint: const Text('Service'),
                      onChanged: (v) {
                        setState(() {
                          _serviceType = v;
                          if (_employee != null && _employee!.department != v) {
                            _employee = null;
                          }
                        });
                      },
                      items: items
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      decoration: _inputDecoration(label: 'Service'),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading services'),
                ),
                const SizedBox(height: 16),

                //
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: _startTime,
                        hint: const Text('Start'),
                        onChanged: (v) {
                          setState(() {
                            _startTime = v;
                            if (_endTime != null &&
                                AddScheduleUtils.timeToDouble(_endTime!) <=
                                    AddScheduleUtils.timeToDouble(v!)) {
                              _endTime = null;
                            }
                          });
                        },
                        items: startTimes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  AddScheduleUtils.formatTimeToAmPm(t),
                                ),
                              ),
                            )
                            .toList(),
                        decoration: _inputDecoration(label: 'Start Time'),
                      ),
                    ),

                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: _endTime,
                        hint: const Text('End'),
                        onChanged: (v) => setState(() => _endTime = v),
                        items: endTimes.map((t) {
                          final duration = _startTime != null
                              ? AddScheduleUtils.calculateDurationLabel(
                                  _startTime!,
                                  t,
                                )
                              : '';
                          return DropdownMenuItem(
                            value: t,
                            child: Text(
                              '${AddScheduleUtils.formatTimeToAmPm(t)} ($duration)',
                            ),
                          );
                        }).toList(),
                        decoration: _inputDecoration(label: 'End Time'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SessionType>(
                        value: _sessionType,
                        onChanged: (v) => setState(() => _sessionType = v!),
                        items: SessionType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              ),
                            )
                            .toList(),
                        decoration: _inputDecoration(label: 'Type'),
                      ),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<bool>(
                        value: _isInclusive,
                        onChanged: (v) => setState(() => _isInclusive = v!),
                        items: const [
                          DropdownMenuItem(
                            value: false,
                            child: Text('Exclusive'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Inclusive'),
                          ),
                        ],
                        decoration: _inputDecoration(label: 'Session'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onAdd,
          child: Text(isEdit ? 'Update Service' : 'Add Service'),
        ),
      ],
    );
  }

  void _onAdd() {
    if (_employee == null ||
        _startTime == null ||
        _endTime == null ||
        _serviceType == null) {
      return;
    }

    if (AddScheduleUtils.timeToDouble(_endTime!) <=
        AddScheduleUtils.timeToDouble(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final service = ServiceDetail(
      type: _serviceType!,
      startTime: _startTime!,
      endTime: _endTime!,
      employeeId: _employee!.id,
      isInclusive: _isInclusive,
      sessionType: _sessionType,
    );

    Navigator.pop(context, service);
  }

  InputDecoration _inputDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: const TextStyle(fontSize: 14),
    );
  }
}
