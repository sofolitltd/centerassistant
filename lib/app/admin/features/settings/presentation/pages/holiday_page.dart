import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _activeTab = 0; // 0: Weekly/Special, 1: Public Holidays

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
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildTabSwitcher(),
                  const SizedBox(height: 32),
                  if (_activeTab == 0) ...[
                    _buildWeeklySection(settingsAsync),
                    const SizedBox(height: 48),
                    _buildSpecialWorkSection(settingsAsync),
                  ] else ...[
                    _buildHolidaysSection(holidaysAsync),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
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
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              const Text(
                'Settings',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              const Text('Holidays', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Holidays',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Row(
      children: [
        _TabButton(
          label: 'Weekly & Special Days',
          isSelected: _activeTab == 0,
          onTap: () => setState(() => _activeTab = 0),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Public Holidays',
          isSelected: _activeTab == 1,
          onTap: () => setState(() => _activeTab = 1),
        ),
      ],
    );
  }

  Widget _buildWeeklySection(AsyncValue<OfficeSettings> settingsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Weekly Off-Days', LucideIcons.calendar),
        const SizedBox(height: 16),
        settingsAsync.when(
          data: (settings) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _daysOfWeek.map<Widget>((day) {
              final isSelected = settings.weeklyOffDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) => _toggleDay(day, isSelected),
              );
            }).toList(),
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
        _buildSectionHeader(
          'Special Work Days (Override)',
          LucideIcons.briefcase,
        ),
        const SizedBox(height: 8),
        const Text(
          'Select dates when the office remains OPEN even if it falls on a weekend or holiday.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        settingsAsync.when(
          data: (settings) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddSpecialWorkDayDialog(context),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Special Work Day'),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: settings.specialWorkDays.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final swd = settings.specialWorkDays[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(
                          LucideIcons.briefcase,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        DateFormat('EEEE, MMM d, yyyy').format(swd.date),
                      ),
                      subtitle: swd.note != null ? Text(swd.note!) : null,
                      trailing: IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => _confirmRemoveSpecialWorkDay(swd),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Public Holidays', LucideIcons.flag),
            ElevatedButton.icon(
              onPressed: () => _showAddHolidayDialog(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Holiday'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        holidaysAsync.when(
          data: (holidays) => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: holidays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final holiday = holidays[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(holiday.title),
                  subtitle: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(holiday.date),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      LucideIcons.trash2,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => _confirmDeleteHoliday(holiday),
                  ),
                ),
              );
            },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      'Remove Special Work Day',
      'Are you sure you want to remove the override for ${DateFormat('MMM d, yyyy').format(swd.date)}?',
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
          final years = List.generate(11, (i) => 2020 + i);
          final months = List.generate(12, (i) => i + 1);

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
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedDate.year,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                            ),
                            items: years
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(
                                  () => selectedDate = DateTime(
                                    v,
                                    selectedDate.month,
                                    selectedDate.day,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedDate.month,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              border: OutlineInputBorder(),
                            ),
                            items: months
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      DateFormat(
                                        'MMMM',
                                      ).format(DateTime(2024, m)),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(
                                  () => selectedDate = DateTime(
                                    selectedDate.year,
                                    v,
                                    selectedDate.day,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 350,
                      child: CalendarDatePicker(
                        key: ValueKey(
                          '${selectedDate.year}-${selectedDate.month}',
                        ),
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        currentDate: selectedDate,
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
                          vertical: 8,
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
          final years = List.generate(11, (i) => 2020 + i);
          final months = List.generate(12, (i) => i + 1);

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
                          'Add Special Work Day',
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
                      'Office will be open on this day.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedDate.year,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                            ),
                            items: years
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(
                                  () => selectedDate = DateTime(
                                    v,
                                    selectedDate.month,
                                    selectedDate.day,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedDate.month,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              border: OutlineInputBorder(),
                            ),
                            items: months
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      DateFormat(
                                        'MMMM',
                                      ).format(DateTime(2024, m)),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(
                                  () => selectedDate = DateTime(
                                    selectedDate.year,
                                    v,
                                    selectedDate.day,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 350,
                      child: CalendarDatePicker(
                        key: ValueKey(
                          '${selectedDate.year}-${selectedDate.month}',
                        ),
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        currentDate: selectedDate,
                        onDateChanged: (date) =>
                            setState(() => selectedDate = date),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                              (d) =>
                                  d.date.year == selectedDate.year &&
                                  d.date.month == selectedDate.month &&
                                  d.date.day == selectedDate.day,
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
                          child: const Text('Add Work Day'),
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

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black54,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
