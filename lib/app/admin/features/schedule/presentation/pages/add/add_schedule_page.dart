import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/models/employee.dart';
import '/core/models/schedule_template.dart';
import '/core/models/session.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import '/core/providers/time_slot_providers.dart';
import 'add_schedule_utils.dart';
import 'widgets/add_schedule_client_section.dart';
import 'widgets/add_schedule_date_time_section.dart';
import 'widgets/add_schedule_footer.dart';
import 'widgets/add_schedule_header.dart';
import 'widgets/add_schedule_pending_list.dart';
import 'widgets/add_schedule_recurring_section.dart';
import 'widgets/add_schedule_service_dialog.dart';

class AddSchedulePage extends ConsumerStatefulWidget {
  final String? initialClientId;
  final String? initialTimeSlotId;
  final String? initialEmployeeId;
  final DateTime? initialDate;

  const AddSchedulePage({
    super.key,
    this.initialClientId,
    this.initialTimeSlotId,
    this.initialEmployeeId,
    this.initialDate,
  });

  @override
  ConsumerState<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends ConsumerState<AddSchedulePage> {
  Client? _selectedClient;
  Employee? _builderEmployee;

  // Time selection defaults for service builder
  String? _builderStartTime;
  String? _builderEndTime;

  final List<ServiceDetail> _pendingServices = [];
  String? _selectedTimeSlotId;
  bool _isRecurring = true;

  // Simplified Recurring State (Weekly Only)
  final int _interval = 1;
  final RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  List<String> _selectedDays = [];
  RecurrenceEndType _endType = RecurrenceEndType.onDate;
  DateTime? _endDate;
  int _occurrences = 1;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final scheduleAsync = ref.watch(scheduleViewProvider);

    // Initializations from query parameters
    if (!_initialized &&
        clientsAsync.hasValue &&
        employeesAsync.hasValue &&
        timeSlotsAsync.hasValue) {
      if (widget.initialClientId != null) {
        final clients = clientsAsync.value ?? [];
        _selectedClient = clients
            .where((c) => c.id == widget.initialClientId)
            .firstOrNull;
      }
      if (widget.initialTimeSlotId != null) {
        _selectedTimeSlotId = widget.initialTimeSlotId;
        final slot = timeSlotsAsync.value
            ?.where((s) => s.id == _selectedTimeSlotId)
            .firstOrNull;
        if (slot != null) {
          _builderStartTime = AddScheduleUtils.normalizeTime(slot.startTime);
          _builderEndTime = AddScheduleUtils.normalizeTime(slot.endTime);
        }
      }
      if (widget.initialEmployeeId != null) {
        final employees = employeesAsync.value ?? [];
        _builderEmployee = employees
            .where((e) => e.id == widget.initialEmployeeId)
            .firstOrNull;
      }
      if (widget.initialDate != null) {
        Future.microtask(() {
          ref.read(selectedDateProvider.notifier).setDate(widget.initialDate!);
        });
      }
      _selectedDays = [DateFormat('EEEE').format(selectedDate)];
      // Default end date to last date of selected month
      _endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      _initialized = true;
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    const AddScheduleHeader(),
                    const SizedBox(height: 32),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AddScheduleDateTimeSection(
                                selectedDate: selectedDate,
                                timeSlotsAsync: timeSlotsAsync,
                                selectedTimeSlotId: _selectedTimeSlotId,
                                onDateChanged: (picked) {
                                  ref
                                      .read(selectedDateProvider.notifier)
                                      .setDate(picked);
                                  setState(() {
                                    _selectedDays = [
                                      DateFormat('EEEE').format(picked),
                                    ];
                                    _endDate = DateTime(
                                      picked.year,
                                      picked.month + 1,
                                      0,
                                    );
                                  });
                                },
                                onTimeSlotChanged: (v, slot) {
                                  setState(() {
                                    _selectedTimeSlotId = v;
                                    if (slot != null) {
                                      _builderStartTime =
                                          AddScheduleUtils.normalizeTime(
                                            slot.startTime,
                                          );
                                      _builderEndTime =
                                          AddScheduleUtils.normalizeTime(
                                            slot.endTime,
                                          );
                                    }
                                  });
                                },
                                formatTimeToAmPm:
                                    AddScheduleUtils.formatTimeToAmPm,
                              ),

                              const SizedBox(height: 16),

                              //
                              AddScheduleClientSection(
                                clientsAsync: clientsAsync,
                                selectedClient: _selectedClient,
                                onClientChanged: (c) =>
                                    setState(() => _selectedClient = c),
                                selectedTimeSlotId: _selectedTimeSlotId,
                                scheduleAsync: scheduleAsync,
                              ),

                              const SizedBox(height: 32),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Services',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _handleOpenServiceDialog(),
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      size: 18,
                                    ),
                                    label: const Text('Add Service'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              AddSchedulePendingList(
                                pendingServices: _pendingServices,
                                getEmployee: _getEmployee,
                                formatTimeToAmPm:
                                    AddScheduleUtils.formatTimeToAmPm,
                                onRemoveService: (index) => setState(
                                  () => _pendingServices.removeAt(index),
                                ),
                                onEditService: (index, service) =>
                                    _handleOpenServiceDialog(
                                      index: index,
                                      initialService: service,
                                    ),
                              ),

                              const SizedBox(height: 32),

                              AddScheduleRecurringSection(
                                isRecurring: _isRecurring,
                                onRecurringChanged: (v) =>
                                    setState(() => _isRecurring = v),
                                selectedDays: _selectedDays,
                                endType: _endType,
                                endDate: _endDate,
                                occurrences: _occurrences,
                                onDaysChanged: (days) =>
                                    setState(() => _selectedDays = days),
                                onEndTypeChanged: (type) =>
                                    setState(() => _endType = type),
                                onEndDateChanged: (date) =>
                                    setState(() => _endDate = date),
                                onOccurrencesChanged: (count) =>
                                    setState(() => _occurrences = count),
                              ),

                              const SizedBox(height: 24),

                              AddScheduleFooter(
                                isSaveEnabled:
                                    !(_selectedClient == null ||
                                        _pendingServices.isEmpty ||
                                        _selectedTimeSlotId == null ||
                                        _isSaving),
                                onSave: _handleSave,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.white70,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _handleOpenServiceDialog({
    int? index,
    ServiceDetail? initialService,
  }) async {
    if (_selectedTimeSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot first')),
      );
      return;
    }

    Employee? initialEmployee;
    if (initialService != null) {
      initialEmployee = await _getEmployee(initialService.employeeId);
    }

    if (mounted) {
      final result = await showDialog<ServiceDetail>(
        context: context,
        builder: (context) => AddScheduleServiceDialog(
          selectedTimeSlotId: _selectedTimeSlotId,
          initialStartTime: initialService?.startTime ?? _builderStartTime,
          initialEndTime: initialService?.endTime ?? _builderEndTime,
          initialEmployee: initialEmployee ?? _builderEmployee,
          selectedClient: _selectedClient,
          initialService: initialService,
        ),
      );

      if (result != null) {
        setState(() {
          if (index != null) {
            _pendingServices[index] = result;
          } else {
            _pendingServices.add(result);
          }
          _builderEmployee = null;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final selectedDate = ref.read(selectedDateProvider);
      await ref.read(sessionServiceProvider).bookSession(
            clientId: _selectedClient!.id,
            timeSlotId: _selectedTimeSlotId!,
            status: SessionStatus.scheduled,
            services: _pendingServices,
            date: selectedDate,
            isRecurring: _isRecurring,
            frequency: _frequency,
            interval: _interval,
            daysOfWeek: _selectedDays,
            endType: _endType,
            untilDate: _endDate,
            occurrences: _occurrences,
          );

      if (mounted) {
        context.go('/admin/schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<Employee?> _getEmployee(String id) async {
    final employees = ref.read(employeesProvider).value ?? [];
    return employees.where((e) => e.id == id).firstOrNull;
  }
}
