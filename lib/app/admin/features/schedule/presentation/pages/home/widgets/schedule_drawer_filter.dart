import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/client.dart';
import '/core/models/employee.dart';
import '/core/models/session.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';

class ScheduleDrawerFilter extends ConsumerStatefulWidget {
  final String? fixedClientId;
  final String? fixedEmployeeId;

  const ScheduleDrawerFilter({
    super.key,
    this.fixedClientId,
    this.fixedEmployeeId,
  });

  @override
  ConsumerState<ScheduleDrawerFilter> createState() =>
      _ScheduleDrawerFilterState();
}

class _ScheduleDrawerFilterState extends ConsumerState<ScheduleDrawerFilter> {
  late ScheduleFilter _localFilter;

  @override
  void initState() {
    super.initState();
    _localFilter = ref.read(scheduleFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final deptsAsync = ref.watch(schedulableDepartmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Drawer(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Spacer(),
                    //
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _localFilter = ScheduleFilter(
                            clientId: widget.fixedClientId,
                            employeeId: widget.fixedEmployeeId,
                          );
                        });
                        ref
                            .read(scheduleFilterProvider.notifier)
                            .setFilter(_localFilter);
                      },
                      child: const Text('Reset'),
                    ),

                    //
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),

              //
              Expanded(
                child: ButtonTheme(
                  alignedDropdown: true,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildSectionTitle('Client'),
                      clientsAsync.when(
                        data: (clients) => _buildFilterRow(
                          child: DropdownSearch<Client>(
                            enabled: widget.fixedClientId == null,
                            items: (filter, loadProps) => clients,
                            itemAsString: (c) => c.name,
                            compareFn: (a, b) => a.id == b.id,
                            selectedItem: _localFilter.clientId != null
                                ? clients
                                      .where(
                                        (c) => c.id == _localFilter.clientId,
                                      )
                                      .firstOrNull
                                : null,
                            onChanged: (c) => setState(
                              () => _localFilter = _localFilter.copyWith(
                                clientId: () => c?.id,
                              ),
                            ),
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                hintText: 'Select Client',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                fillColor: widget.fixedClientId != null
                                    ? Colors.grey.shade100
                                    : null,
                                filled: widget.fixedClientId != null,
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                            ),
                          ),
                          onClear: () => setState(
                            () => _localFilter = _localFilter.copyWith(
                              clientId: () => null,
                            ),
                          ),
                          showClear:
                              _localFilter.clientId != null &&
                              widget.fixedClientId == null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error'),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Therapist'),
                      employeesAsync.when(
                        data: (employees) {
                          // Filter employees to only those in schedulable departments
                          final schedulableDepts = deptsAsync.value ?? {};
                          final filteredEmployees = employees
                              .where(
                                (e) => schedulableDepts.contains(e.department),
                              )
                              .toList();

                          return _buildFilterRow(
                            child: DropdownSearch<Employee>(
                              enabled: widget.fixedEmployeeId == null,
                              items: (filter, loadProps) => filteredEmployees,
                              itemAsString: (e) => e.name,
                              compareFn: (a, b) => a.id == b.id,
                              selectedItem: _localFilter.employeeId != null
                                  ? filteredEmployees
                                        .where(
                                          (e) =>
                                              e.id == _localFilter.employeeId,
                                        )
                                        .firstOrNull
                                  : null,
                              onChanged: (e) => setState(
                                () => _localFilter = _localFilter.copyWith(
                                  employeeId: () => e?.id,
                                ),
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  hintText: 'Select Therapist',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  fillColor: widget.fixedEmployeeId != null
                                      ? Colors.grey.shade100
                                      : null,
                                  filled: widget.fixedEmployeeId != null,
                                ),
                              ),
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                              ),
                            ),
                            onClear: () => setState(
                              () => _localFilter = _localFilter.copyWith(
                                employeeId: () => null,
                              ),
                            ),
                            showClear:
                                _localFilter.employeeId != null &&
                                widget.fixedEmployeeId == null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error'),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Service'),
                      deptsAsync.when(
                        data: (depts) => _buildFilterRow(
                          child: DropdownButtonFormField<String>(
                            value: _localFilter.serviceType,
                            hint: const Text('Select Service'),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: depts
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _localFilter = _localFilter.copyWith(
                                serviceType: () => v,
                              ),
                            ),
                          ),
                          onClear: () => setState(
                            () => _localFilter = _localFilter.copyWith(
                              serviceType: () => null,
                            ),
                          ),
                          showClear: _localFilter.serviceType != null,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error'),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Status'),
                      _buildFilterRow(
                        child: DropdownButtonFormField<SessionStatus>(
                          value: _localFilter.status,
                          hint: const Text('Select Status'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: SessionStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => _localFilter = _localFilter.copyWith(
                              status: () => v,
                            ),
                          ),
                        ),
                        onClear: () => setState(
                          () => _localFilter = _localFilter.copyWith(
                            status: () => null,
                          ),
                        ),
                        showClear: _localFilter.status != null,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Session Type'),
                      _buildFilterRow(
                        child: DropdownButtonFormField<bool>(
                          value: _localFilter.isInclusive,
                          hint: const Text('Inclusive/Exclusive'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: true,
                              child: Text('Inclusive'),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Exclusive'),
                            ),
                          ],
                          onChanged: (v) => setState(
                            () => _localFilter = _localFilter.copyWith(
                              isInclusive: () => v,
                            ),
                          ),
                        ),
                        onClear: () => setState(
                          () => _localFilter = _localFilter.copyWith(
                            isInclusive: () => null,
                          ),
                        ),
                        showClear: _localFilter.isInclusive != null,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Attendance & Leave'),
                      SwitchListTile(
                        title: const Text(
                          'Client Absence',
                          style: TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: _localFilter.filterClientAbsence ?? false,
                        onChanged: (val) => setState(() {
                          _localFilter = _localFilter.copyWith(
                            filterClientAbsence: () => val ? true : null,
                          );
                        }),
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Therapist Leave',
                          style: TextStyle(fontSize: 14),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: _localFilter.filterTherapistLeave ?? false,
                        onChanged: (val) => setState(() {
                          _localFilter = _localFilter.copyWith(
                            filterTherapistLeave: () => val ? true : null,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(scheduleFilterProvider.notifier)
                          .setFilter(_localFilter);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildFilterRow({
    required Widget child,
    required VoidCallback onClear,
    required bool showClear,
  }) {
    return Row(
      children: [
        Expanded(child: child),
        if (showClear)
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
