import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';

import '/core/providers/client_unavailability_providers.dart';

class ClientLeavePage extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const ClientLeavePage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<ClientLeavePage> createState() => _ClientLeavePageState();
}

class _ClientLeavePageState extends ConsumerState<ClientLeavePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailabilityAsync = ref.watch(
      clientUnavailabilityProvider(widget.clientId),
    );
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/admin/dashboard'),
                  child: Text(
                    'Admin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                InkWell(
                  onTap: () => context.go('/admin/clients'),
                  child: Text(
                    'Clients',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                Text(
                  'Availability: ${widget.clientName}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Manage Absence',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildHistorySection(theme, unavailabilityAsync),
                  ),
                  const SizedBox(width: 32),
                  Expanded(flex: 4, child: _buildActionCard(theme)),
                ],
              )
            else
              Column(
                children: [
                  _buildActionCard(theme),
                  const SizedBox(height: 32),
                  _buildHistorySection(theme, unavailabilityAsync),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark New Absence',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),

            const Text(
              'Select Date or Range',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeSelectionMode,
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _rangeStart =
                        null; // Important: Reset range when single day selected
                    _rangeEnd = null;
                    _rangeSelectionMode = RangeSelectionMode.toggledOff;
                  });
                }
              },
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _selectedDay = null;
                  _focusedDay = focusedDay;
                  _rangeStart = start;
                  _rangeEnd = end;
                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                });
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: theme.colorScheme.primary.withOpacity(0.1),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'e.g. Family vacation',
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    ((_selectedDay == null && _rangeStart == null) ||
                        _isLoading)
                    ? null
                    : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Mark as Absent'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(clientUnavailabilityServiceProvider);

      if (_rangeStart != null && _rangeEnd != null) {
        await service.addUnavailabilityRange(
          clientId: widget.clientId,
          start: _rangeStart!,
          end: _rangeEnd!,
          note: _noteController.text.trim(),
        );
      } else if (_rangeStart != null) {
        // Only start selected (single day range)
        await service.addUnavailability(
          clientId: widget.clientId,
          date: _rangeStart!,
          note: _noteController.text.trim(),
        );
      } else if (_selectedDay != null) {
        await service.addUnavailability(
          clientId: widget.clientId,
          date: _selectedDay!,
          note: _noteController.text.trim(),
        );
      }

      if (mounted) {
        setState(() {
          _selectedDay = null;
          _rangeStart = null;
          _rangeEnd = null;
          _noteController.clear();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absence marked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildHistorySection(
    ThemeData theme,
    AsyncValue<List<dynamic>> unavailabilityAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Absence History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        unavailabilityAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: .zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No history found.')),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = list[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: .zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    visualDensity: .compact,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                      child: Icon(
                        LucideIcons.calendarX,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEEE, MMM dd, yyyy').format(item.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: item.note != null && item.note!.isNotEmpty
                        ? Text(item.note!)
                        : null,
                    trailing: IconButton(
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(item.id),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to remove this absence mark?',
        ),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(clientUnavailabilityServiceProvider)
          .removeUnavailability(id);
    }
  }
}
