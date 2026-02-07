import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/models/employee.dart';
import '/core/models/session.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import '/core/providers/time_slot_providers.dart';
import '../../../../../../../core/models/schedule_template.dart';
import '../add/add_schedule_utils.dart';
import '../add/widgets/add_schedule_client_section.dart';
import '../add/widgets/add_schedule_date_time_section.dart';
import '../add/widgets/add_schedule_footer.dart';
import '../add/widgets/add_schedule_header.dart';
import '../add/widgets/add_schedule_pending_list.dart';
import '../add/widgets/add_schedule_service_dialog.dart';

class EditSchedulePage extends ConsumerStatefulWidget {
  final String sessionId;

  const EditSchedulePage({super.key, required this.sessionId});

  @override
  ConsumerState<EditSchedulePage> createState() => _EditSchedulePageState();
}

class _EditSchedulePageState extends ConsumerState<EditSchedulePage> {
  Client? _selectedClient;
  SessionStatus _status = SessionStatus.scheduled;

  // Time selection defaults for service builder
  String? _builderStartTime;
  String? _builderEndTime;

  List<ServiceDetail> _pendingServices = [];
  String? _selectedTimeSlotId;
  DateTime? _date;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final scheduleAsync = ref.watch(scheduleViewProvider);

    // Fetch session data once
    if (!_initialized &&
        clientsAsync.hasValue &&
        employeesAsync.hasValue &&
        timeSlotsAsync.hasValue) {
      _loadSessionData();
    }

    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    const AddScheduleHeader(title: 'Edit Schedule'),
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
                              // Date & Time Slot Section (Read-only for Edit)
                              AddScheduleDateTimeSection(
                                selectedDate: _date!,
                                timeSlotsAsync: timeSlotsAsync,
                                selectedTimeSlotId: _selectedTimeSlotId,
                                onDateChanged: null,
                                onTimeSlotChanged: null,
                                formatTimeToAmPm:
                                    AddScheduleUtils.formatTimeToAmPm,
                              ),

                              const SizedBox(height: 16),

                              // Client Section (Read-only for Edit)
                              AddScheduleClientSection(
                                clientsAsync: clientsAsync,
                                selectedClient: _selectedClient,
                                onClientChanged: null,
                                selectedTimeSlotId: _selectedTimeSlotId,
                                scheduleAsync: scheduleAsync,
                              ),

                              const SizedBox(height: 32),

                              // Services Section Header
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
                                    onPressed: _handleOpenServiceDialog,
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      size: 18,
                                    ),
                                    label: const Text('Add Service'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Pending List
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

                              // Footer
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

  Future<void> _loadSessionData() async {
    final parts = widget.sessionId.split('_');
    if (parts.length < 3) return;

    final dateStr = parts[0];
    final clientId = parts[1];
    final timeSlotId = parts[2];

    final date = DateFormat('yyyy-MM-dd').parse(dateStr);
    final sessions = await ref
        .read(sessionRepositoryProvider)
        .getSessionsByDate(date);
    final session = sessions.where((s) => s.id == widget.sessionId).firstOrNull;

    if (session == null) {
      if (mounted) context.pop();
      return;
    }

    setState(() {
      _date = date;
      _selectedTimeSlotId = timeSlotId;
      _pendingServices = List.from(session.services);
      _status = session.status;

      final clients = ref.read(clientsProvider).value ?? [];
      _selectedClient = clients.where((c) => c.id == clientId).firstOrNull;

      final slots = ref.read(timeSlotsProvider).value ?? [];
      final slot = slots.where((s) => s.id == timeSlotId).firstOrNull;
      if (slot != null) {
        _builderStartTime = AddScheduleUtils.normalizeTime(slot.startTime);
        _builderEndTime = AddScheduleUtils.normalizeTime(slot.endTime);
      }

      _initialized = true;
    });
  }

  Future<void> _handleOpenServiceDialog({
    int? index,
    ServiceDetail? initialService,
  }) async {
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
          initialEmployee: initialEmployee,
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
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref
          .read(sessionServiceProvider)
          .bookSession(
            clientId: _selectedClient!.id,
            timeSlotId: _selectedTimeSlotId!,
            status: _status,
            services: _pendingServices,
            date: _date!,
            endType: RecurrenceEndType.onDate, // Not recurring
          );

      if (mounted) {
        context.go('/admin/schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating schedule: $e')));
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
