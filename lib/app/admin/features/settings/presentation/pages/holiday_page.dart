import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/office_settings.dart';
import '/core/providers/office_settings_providers.dart';
import '/services/firebase_service.dart';

class HolidayPage extends ConsumerStatefulWidget {
  const HolidayPage({super.key});

  @override
  ConsumerState<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends ConsumerState<HolidayPage> {
  String _activeTab =
      'Public Holidays'; // 'Public Holidays', 'Weekly Off-Days', or 'Special Working Days'
  String _holidaySubTab = 'Upcoming'; // 'Upcoming' or 'Archived'
  String _specialSubTab = 'Upcoming'; // 'Upcoming' or 'Archived'
  String _weeklySubTab = 'Active'; // 'Active', 'Upcoming', 'Expired', or 'All'

  final List<String> _daysOfWeek = [
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
    final holidaysAsync = ref.watch(officeHolidaysProvider);
    final specialWorkDaysAsync = ref.watch(specialWorkDaysProvider);
    final weeklyPoliciesAsync = ref.watch(weeklyOffDayPoliciesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final headerContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/admin/dashboard'),
                          child: const Text(
                            'Admin',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Text(
                          'Settings',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const Text(
                          'Holidays',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Center Holidays',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                    ),
                  ],
                );

                Widget? actionButton;
                if (_activeTab == 'Public Holidays') {
                  actionButton = ElevatedButton.icon(
                    onPressed: () => _showAddHolidayDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Holiday'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  );
                } else if (_activeTab == 'Weekly Off-Days') {
                  actionButton = ElevatedButton.icon(
                    onPressed: () => _showAddPolicyDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('New Policy'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  );
                } else if (_activeTab == 'Special Working Days') {
                  actionButton = ElevatedButton.icon(
                    onPressed: () => _showAddSpecialWorkDayDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Special Day'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  );
                }

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerContent,
                      if (actionButton != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: actionButton),
                      ],
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    headerContent,
                    if (actionButton != null) actionButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Filters (Tabs)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton('Public Holidays'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Weekly Off-Days'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Special Working Days'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_activeTab == 'Public Holidays') ...[
              _buildHolidaysSection(holidaysAsync),
            ] else if (_activeTab == 'Weekly Off-Days') ...[
              _buildWeeklySection(weeklyPoliciesAsync),
            ] else ...[
              _buildSpecialWorkSection(specialWorkDaysAsync),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    String label, {
    bool isSubTab = false,
    bool isSpecial = false,
    bool isWeekly = false,
  }) {
    final isSelected = isSubTab
        ? (isSpecial
              ? _specialSubTab == label
              : (isWeekly ? _weeklySubTab == label : _holidaySubTab == label))
        : _activeTab == label;
    return InkWell(
      onTap: () => setState(() {
        if (isSubTab) {
          if (isSpecial) {
            _specialSubTab = label;
          } else if (isWeekly) {
            _weeklySubTab = label;
          } else {
            _holidaySubTab = label;
          }
        } else {
          _activeTab = label;
        }
      }),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: isSubTab ? 12 : 13,
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader({
    required String title,
    required IconData icon,
    required String subtitle,
    required List<Widget> subTabs,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final titleAndSubtitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title, icon),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        );

        final tabsWidget = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisSize: MainAxisSize.min, children: subTabs),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleAndSubtitle,
              const SizedBox(height: 16),
              tabsWidget,
              const SizedBox(height: 24),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleAndSubtitle),
                const SizedBox(width: 16),
                tabsWidget,
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildWeeklySection(
    AsyncValue<List<WeeklyOffDayPolicy>> policiesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: 'Weekly Off-Days Policies',
          icon: LucideIcons.calendar,
          subtitle:
              'Configure recurring off-days using versioned policies for historical accuracy.',
          subTabs: [
            _buildFilterButton('Active', isSubTab: true, isWeekly: true),
            const SizedBox(width: 4),
            _buildFilterButton('Upcoming', isSubTab: true, isWeekly: true),
            const SizedBox(width: 4),
            _buildFilterButton('Expired', isSubTab: true, isWeekly: true),
            const SizedBox(width: 4),
            _buildFilterButton('All', isSubTab: true, isWeekly: true),
          ],
        ),
        policiesAsync.when(
          data: (policies) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final filtered = policies.where((p) {
              final isStarted =
                  p.startDate.isBefore(today) ||
                  (p.startDate.year == today.year &&
                      p.startDate.month == today.month &&
                      p.startDate.day == today.day);
              final hasEnded =
                  p.endDate != null &&
                  p.endDate!.isBefore(today) &&
                  !(p.endDate!.year == today.year &&
                      p.endDate!.month == today.month &&
                      p.endDate!.day == today.day);

              final isActive = isStarted && !hasEnded;
              final isUpcoming = p.startDate.isAfter(today);
              final isExpired = hasEnded;

              switch (_weeklySubTab) {
                case 'Active':
                  return isActive;
                case 'Upcoming':
                  return isUpcoming;
                case 'Expired':
                  return isExpired;
                default:
                  return true;
              }
            }).toList();

            if (filtered.isEmpty) {
              return _buildEmptyState(
                'No $_weeklySubTab weekly policies found.',
              );
            }

            return _buildDataTable(
              columns: const [
                DataColumn2(label: Text('Effective Date'), size: ColumnSize.L),
                DataColumn2(label: Text('Off Days'), size: ColumnSize.L),
                DataColumn2(label: Text('End Date'), fixedWidth: 120),
                DataColumn2(label: Text('Action'), fixedWidth: 80),
              ],
              rows: filtered.map((p) {
                return DataRow2(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('dd-MMM-yyyy').format(p.startDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (p.note != null)
                            Text(
                              p.note!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        children: p.days.map((d) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    DataCell(
                      Text(
                        p.endDate != null
                            ? DateFormat('dd-MMM-yyyy').format(p.endDate!)
                            : 'Ongoing',
                        style: TextStyle(
                          color: p.endDate != null ? Colors.red : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        color: Colors.red.shade300,
                        onPressed: () => _confirmDeletePolicy(p),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildSpecialWorkSection(
    AsyncValue<List<SpecialWorkDay>> specialAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: 'Special Working Days',
          icon: LucideIcons.briefcase,
          subtitle:
              'Specific dates when the center will remain OPEN (overrides off-days or holidays).',
          subTabs: [
            _buildFilterButton('Upcoming', isSubTab: true, isSpecial: true),
            const SizedBox(width: 4),
            _buildFilterButton('Archived', isSubTab: true, isSpecial: true),
          ],
        ),
        specialAsync.when(
          data: (specialDays) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final filtered = specialDays.where((swd) {
              final dDate = DateTime(
                swd.date.year,
                swd.date.month,
                swd.date.day,
              );
              if (_specialSubTab == 'Upcoming') {
                return dDate.isAtSameMomentAs(today) || dDate.isAfter(today);
              } else {
                return dDate.isBefore(today);
              }
            }).toList();

            if (filtered.isEmpty) {
              return _buildEmptyState(
                _specialSubTab == 'Upcoming'
                    ? 'No upcoming special working days.'
                    : 'No archived special working days.',
              );
            }

            final sortedWorkDays = List<SpecialWorkDay>.from(filtered)
              ..sort((a, b) {
                if (_specialSubTab == 'Upcoming') {
                  return a.date.compareTo(b.date);
                } else {
                  return b.date.compareTo(a.date);
                }
              });

            return _buildDataTable(
              columns: const [
                DataColumn2(label: Text('Date'), size: ColumnSize.L),
                DataColumn2(label: Text('Holiday Title'), size: ColumnSize.L),
                DataColumn2(label: Text('Day'), fixedWidth: 120),
                DataColumn2(label: Text('Action'), fixedWidth: 80),
              ],
              rows: sortedWorkDays.map((swd) {
                return DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        DateFormat('dd-MM-yyyy').format(swd.date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        swd.note ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    DataCell(Text(DateFormat('EEEE').format(swd.date))),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmRemoveSpecialWorkDay(swd),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(),
          error: (_, ___) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHolidaysSection(AsyncValue<List<OfficeHoliday>> holidaysAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentHeader(
          title: 'Public Holidays List',
          icon: LucideIcons.flag,
          subtitle:
              'Manage national and center-specific holidays when the center will be closed.',
          subTabs: [
            _buildFilterButton('Upcoming', isSubTab: true),
            const SizedBox(width: 4),
            _buildFilterButton('Archived', isSubTab: true),
          ],
        ),
        holidaysAsync.when(
          data: (holidays) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final filtered = holidays.where((h) {
              final hDate = DateTime(h.date.year, h.date.month, h.date.day);
              if (_holidaySubTab == 'Upcoming') {
                return hDate.isAtSameMomentAs(today) || hDate.isAfter(today);
              } else {
                return hDate.isBefore(today);
              }
            }).toList();

            if (filtered.isEmpty) {
              return _buildEmptyState(
                _holidaySubTab == 'Upcoming'
                    ? 'No upcoming public holidays.'
                    : 'No archived public holidays.',
              );
            }

            final sorted = List<OfficeHoliday>.from(filtered)
              ..sort((a, b) {
                if (_holidaySubTab == 'Upcoming') {
                  return a.date.compareTo(b.date);
                } else {
                  return b.date.compareTo(a.date);
                }
              });

            return _buildDataTable(
              columns: const [
                DataColumn2(label: Text('Date'), size: ColumnSize.L),
                DataColumn2(label: Text('Holiday Title'), size: ColumnSize.L),
                DataColumn2(label: Text('Day'), fixedWidth: 120),
                DataColumn2(label: Text('Action'), fixedWidth: 80),
              ],
              rows: sorted.map((h) {
                return DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        DateFormat('dd-MM-yyyy').format(h.date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(h.title)),
                    DataCell(Text(DateFormat('EEEE').format(h.date))),
                    DataCell(
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteHoliday(h),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildDataTable({
    required List<DataColumn2> columns,
    required List<DataRow2> rows,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        height: rows.length * 48 + 56,
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 600,
          headingRowHeight: 48,
          dataRowHeight: 48,
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade100),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(message, style: const TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Future<void> _showAddPolicyDialog(BuildContext context) async {
    final noteController = TextEditingController();
    DateTime startDate = DateTime.now();
    List<String> selectedDays = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 500, maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Create New Weekly Policy',
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
                      const SizedBox(height: 8),
                      const Text(
                        'This will set the recurring off-days starting from the selected date.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Select Off-Days:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _daysOfWeek.map((day) {
                          final isSelected = selectedDays.contains(day);
                          return FilterChip(
                            label: Text(day),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Effective Date:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      CalendarDatePicker(
                        initialDate: startDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime(2030),
                        onDateChanged: (val) => setState(() => startDate = val),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          hintText: 'e.g., Summer Schedule 2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedDays.isEmpty) return;

                              final firestore = ref.read(firestoreProvider);

                              // Find current active policy and set its endDate
                              final policies = await ref.read(
                                weeklyOffDayPoliciesProvider.future,
                              );
                              final currentActive = policies
                                  .where((p) => p.endDate == null)
                                  .firstOrNull;

                              final batch = firestore.batch();

                              if (currentActive != null) {
                                batch.update(
                                  firestore
                                      .collection('weekly_off_day_configs')
                                      .doc(currentActive.id),
                                  {
                                    'endDate': Timestamp.fromDate(
                                      startDate.subtract(
                                        const Duration(days: 1),
                                      ),
                                    ),
                                  },
                                );
                              }

                              final newPolicyDoc = firestore
                                  .collection('weekly_off_day_configs')
                                  .doc();
                              batch.set(newPolicyDoc, {
                                'days': selectedDays,
                                'startDate': Timestamp.fromDate(startDate),
                                'endDate': null,
                                'note': noteController.text.isEmpty
                                    ? null
                                    : noteController.text,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              await batch.commit();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text('Activate Policy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeletePolicy(WeeklyOffDayPolicy policy) async {
    final confirmed = await _showConfirmDialog(
      'Delete Policy',
      'Are you sure you want to delete this policy? This might affect historical data.',
    );
    if (confirmed == true) {
      await ref
          .read(firestoreProvider)
          .collection('weekly_off_day_configs')
          .doc(policy.id)
          .delete();
    }
  }

  Future<void> _confirmRemoveSpecialWorkDay(SpecialWorkDay swd) async {
    final confirmed = await _showConfirmDialog(
      'Remove Special Day',
      'Are you sure you want to remove this override?',
    );
    if (confirmed == true) {
      await ref
          .read(firestoreProvider)
          .collection('special_working_days')
          .doc(swd.id)
          .delete();
    }
  }

  Future<void> _showAddSpecialWorkDayDialog(BuildContext context) async {
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 400, maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Special Day',
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
                    SizedBox(
                      height: 350,
                      child: CalendarDatePicker(
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        onDateChanged: (date) =>
                            setState(() => selectedDate = date),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Note',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final firestore = ref.read(firestoreProvider);

                            await firestore
                                .collection('special_working_days')
                                .add({
                                  'date': Timestamp.fromDate(selectedDate),
                                  'note': noteController.text.isEmpty
                                      ? null
                                      : noteController.text,
                                });

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Add Override'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHoliday(OfficeHoliday holiday) async {
    final confirmed = await _showConfirmDialog(
      'Delete Holiday',
      'Are you sure you want to delete "${holiday.title}"?',
    );
    if (confirmed == true) {
      await ref
          .read(firestoreProvider)
          .collection('holidays')
          .doc(holiday.id)
          .delete();
    }
  }

  Future<void> _showAddHolidayDialog(BuildContext context) async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 400, maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Public Holiday',
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
                    SizedBox(
                      height: 350,
                      child: CalendarDatePicker(
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        onDateChanged: (date) =>
                            setState(() => selectedDate = date),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Holiday Title',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isNotEmpty) {
                              await ref
                                  .read(firestoreProvider)
                                  .collection('holidays')
                                  .add({
                                    'title': titleController.text,
                                    'date': Timestamp.fromDate(selectedDate),
                                    'isCenterWide': true,
                                  });
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          child: const Text('Save Holiday'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
