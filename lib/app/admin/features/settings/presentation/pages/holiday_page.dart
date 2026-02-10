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
      'Weekly Off-Days'; // 'Weekly Off-Days' or 'Public Holidays'

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
    final settingsAsync = ref.watch(officeSettingsProvider);
    final holidaysAsync = ref.watch(officeHolidaysProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs & Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                ),
                if (_activeTab == 'Public Holidays')
                  ElevatedButton.icon(
                    onPressed: () => _showAddHolidayDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Public Holiday'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _showAddSpecialWorkDayDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add Special Day'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters (Tabs)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildFilterButton('Weekly Off-Days'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Public Holidays'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_activeTab == 'Weekly Off-Days') ...[
              _buildWeeklySection(settingsAsync),
              const SizedBox(height: 48),
              _buildSpecialWorkSection(settingsAsync),
            ] else ...[
              _buildHolidaysSection(holidaysAsync),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = _activeTab == label;
    return InkWell(
      onTap: () => setState(() => _activeTab = label),
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySection(AsyncValue<OfficeSettings> settingsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Weekly Recurring Off-Days', LucideIcons.calendar),
        const SizedBox(height: 16),
        settingsAsync.when(
          data: (settings) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _daysOfWeek.map<Widget>((day) {
                  final isSelected = settings.weeklyOffDays.contains(day);
                  return ChoiceChip(
                    label: Text(day, style: const TextStyle(fontSize: 13)),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    onSelected: (selected) => _toggleDay(day, isSelected),
                  );
                }).toList(),
              ),
            ),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildSpecialWorkSection(AsyncValue<OfficeSettings> settingsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Special Working Days', LucideIcons.briefcase),
        const SizedBox(height: 8),
        const Text(
          'Specific dates when the center will remain OPEN (overrides off-days or holidays).',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        settingsAsync.when(
          data: (settings) {
            if (settings.specialWorkDays.isEmpty) {
              return _buildEmptyState('No special working days defined.');
            }
            return _buildDataTable(
              columns: const [
                DataColumn2(label: Text('Date'), size: ColumnSize.L),
                DataColumn2(label: Text('Holiday Title'), size: ColumnSize.L),
                DataColumn2(label: Text('Day'), fixedWidth: 120),
                DataColumn2(label: Text('Action'), fixedWidth: 80),
              ],
              rows: settings.specialWorkDays.map((swd) {
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
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildHolidaysSection(AsyncValue<List<OfficeHoliday>> holidaysAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Public Holidays List', LucideIcons.flag),
        const SizedBox(height: 16),
        holidaysAsync.when(
          data: (holidays) {
            if (holidays.isEmpty) {
              return _buildEmptyState(
                'No public holidays listed for this year.',
              );
            }
            final sorted = List<OfficeHoliday>.from(holidays)
              ..sort((a, b) => b.date.compareTo(a.date));
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

  Future<void> _toggleDay(String day, bool isCurrentlySelected) async {
    final confirmed = await _showConfirmDialog(
      'Update Off-Day',
      'Are you sure you want to ${isCurrentlySelected ? 'remove' : 'add'} $day as a weekly off-day?',
    );

    if (confirmed == true) {
      final firestore = ref.read(firestoreProvider);
      final settings = await ref.read(officeSettingsProvider.future);

      final newDays = List<String>.from(settings.weeklyOffDays);
      if (isCurrentlySelected) {
        newDays.remove(day);
      } else {
        newDays.add(day);
      }

      await firestore.collection('settings').doc('office').set({
        'weeklyOffDays': newDays,
      }, SetOptions(merge: true));
    }
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

  Future<void> _confirmRemoveSpecialWorkDay(SpecialWorkDay swd) async {
    final confirmed = await _showConfirmDialog(
      'Remove Special Day',
      'Are you sure you want to remove this override?',
    );
    if (confirmed == true) {
      final firestore = ref.read(firestoreProvider);
      final settings = await ref.read(officeSettingsProvider.future);
      final newWorkDays = settings.specialWorkDays
          .where((d) => d.date != swd.date)
          .toList();

      await firestore.collection('settings').doc('office').set({
        'specialWorkDays': newWorkDays.map((d) => d.toJson()).toList(),
      }, SetOptions(merge: true));
    }
  }

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
                            final settings = await ref.read(
                              officeSettingsProvider.future,
                            );
                            final newWorkDays = List<SpecialWorkDay>.from(
                              settings.specialWorkDays,
                            );

                            if (!newWorkDays.any(
                              (d) => isSameDay(d.date, selectedDate),
                            )) {
                              newWorkDays.add(
                                SpecialWorkDay(
                                  date: selectedDate,
                                  note: noteController.text.isEmpty
                                      ? null
                                      : noteController.text,
                                ),
                              );
                            }

                            await firestore
                                .collection('settings')
                                .doc('office')
                                .set({
                                  'specialWorkDays': newWorkDays
                                      .map((d) => d.toJson())
                                      .toList(),
                                }, SetOptions(merge: true));

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
}
