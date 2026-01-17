import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '/core/models/session.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/session_providers.dart';
import 'assign_cover_dialog.dart';

class SessionCard extends ConsumerWidget {
  final SessionCardData session;
  final String timeSlotId;

  const SessionCard({
    super.key,
    required this.session,
    required this.timeSlotId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardColor = _getSessionColor(session.sessionType);
    final isRegular = session.sessionType == SessionType.regular;
    final isCancelled =
        session.sessionType == SessionType.cancelled ||
        session.sessionType == SessionType.cancelledCenter ||
        session.sessionType == SessionType.cancelledClient;
    final isCompleted = session.sessionType == SessionType.completed;

    // Generate deterministic session ID using clientDocId
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final sessionId = "${dateStr}_${session.clientDocId}_$timeSlotId";

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: isRegular
              ? Colors.black12.withValues(alpha: 0.05)
              : _getStatusBorderColor(session.sessionType),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.displayFullName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isCancelled
                              ? Colors.red.shade900
                              : (isCompleted ? Colors.green.shade900 : null),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                      child: Text(
                        _getStatusLabel(session.sessionType),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isCancelled
                              ? Colors.red.shade900
                              : (isCompleted
                                    ? Colors.green.shade900
                                    : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Services Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 4,
                    children: session.services.map((service) {
                      return _ServiceChip(
                        service: service,
                        isCancelled: isCancelled,
                        isCompleted: isCompleted,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: PopupMenuButton<int>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: Colors.black54,
              ),
              padding: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (value) {
                if (value == 1) {
                  _showAssignCoverDialog(context, ref);
                } else if (value == 2) {
                  _showCancelDialog(context, ref);
                } else if (value == 3) {
                  // Restore to regular
                  if (session.templateEmployeeId != null) {
                    ref
                        .read(sessionServiceProvider)
                        .assignCover(
                          session.clientDocId,
                          timeSlotId,
                          session.templateEmployeeId!,
                          session.templateEmployeeId,
                          session.services,
                        );
                  }
                } else if (value == 4) {
                  ref
                      .read(sessionServiceProvider)
                      .completeSession(
                        session.clientDocId,
                        timeSlotId,
                        session.services,
                      );
                } else if (value == 5) {
                  context.push('/admin/schedule/edit/$sessionId');
                }
              },
              itemBuilder: (context) => [
                // Edit
                const PopupMenuItem(
                  value: 5,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, size: 18),
                    title: Text('Edit Schedule'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),

                // 1. Mark as Completed
                if (!isCompleted && !isCancelled)
                  const PopupMenuItem(
                    value: 4,
                    child: ListTile(
                      leading: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.green,
                      ),
                      title: Text('Mark Completed'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),

                // 2. Assign Cover
                const PopupMenuItem(
                  value: 1,
                  child: ListTile(
                    leading: Icon(Icons.person_outline, size: 18),
                    title: Text('Assign Cover'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),

                // 3. Restore Regular
                if (!isRegular)
                  const PopupMenuItem(
                    value: 3,
                    child: ListTile(
                      leading: Icon(
                        Icons.history,
                        size: 18,
                        color: Colors.blue,
                      ),
                      title: Text('Restore Regular'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),

                // 4. Cancel
                if (!isCancelled && !isCompleted)
                  const PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      leading: Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: Colors.red,
                      ),
                      title: Text(
                        'Cancel Session',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(SessionType type) {
    switch (type) {
      case SessionType.cancelledCenter:
        return 'CENTER CANCELLED';
      case SessionType.cancelledClient:
        return 'CLIENT CANCELLED';
      default:
        return type.name.toUpperCase();
    }
  }

  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.regular:
        return Colors.white;
      case SessionType.cover:
        return const Color(0xFFFFF7ED);
      case SessionType.makeup:
        return const Color(0xFFEFF6FF);
      case SessionType.extra:
        return const Color(0xFFF0FDF4);
      case SessionType.cancelled:
      case SessionType.cancelledCenter:
      case SessionType.cancelledClient:
        return const Color(0xFFFEF2F2);
      case SessionType.completed:
        return const Color(0xFFF0FDF4);
    }
  }

  Color _getStatusBorderColor(SessionType type) {
    switch (type) {
      case SessionType.cover:
        return Colors.orange.shade200;
      case SessionType.makeup:
        return Colors.blue.shade200;
      case SessionType.extra:
        return Colors.green.shade200;
      case SessionType.cancelled:
      case SessionType.cancelledCenter:
      case SessionType.cancelledClient:
        return Colors.red.shade200;
      case SessionType.completed:
        return Colors.green.shade300;
      case SessionType.regular:
        return Colors.transparent;
    }
  }

  void _showAssignCoverDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) =>
          AssignCoverDialog(session: session, timeSlotId: timeSlotId),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    SessionType selectedType = SessionType.cancelledClient;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 350),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cancel Session'),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButtonFormField<SessionType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Cancel by',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SessionType.cancelledClient,
                      child: Text('Client'),
                    ),
                    DropdownMenuItem(
                      value: SessionType.cancelledCenter,
                      child: Text('Center'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(sessionServiceProvider)
                    .cancelSession(
                      session.clientDocId,
                      timeSlotId,
                      selectedType,
                      session.services,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceChip extends ConsumerWidget {
  final ServiceDetail service;
  final bool isCancelled;
  final bool isCompleted;

  const _ServiceChip({
    required this.service,
    required this.isCancelled,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return employeesAsync.when(
      data: (employees) {
        final employee = employees
            .where((e) => e.id == service.employeeId)
            .firstOrNull;
        final name = employee?.nickName ?? 'Unknown';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
          ),
          child: Text(
            '${service.type} | $name | ${service.duration} h'.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isCancelled
                  ? Colors.red.shade800
                  : (isCompleted ? Colors.green.shade800 : Colors.black),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}
