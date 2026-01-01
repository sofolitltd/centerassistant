import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/models/session.dart';
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
    final isCancelled = session.sessionType == SessionType.cancelled;
    final isCompleted = session.sessionType == SessionType.completed;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRegular
              ? Colors.grey.withValues(alpha: 0.2)
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
                        session.clientName,
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
                        session.sessionType.name.toUpperCase(),
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
                Row(
                  children: [
                    Text(
                      'Employee: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isCancelled
                            ? Colors.red.shade700
                            : (isCompleted
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.employeeName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isCancelled
                              ? Colors.red.shade800
                              : (isCompleted
                                    ? Colors.green.shade800
                                    : Colors.black),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                  ref
                      .read(sessionServiceProvider)
                      .cancelSession(
                        session.clientId,
                        timeSlotId,
                        session.employeeId,
                      );
                } else if (value == 3) {
                  // Restore to regular
                  if (session.templateEmployeeId != null) {
                    ref
                        .read(sessionServiceProvider)
                        .assignCover(
                          session.clientId,
                          timeSlotId,
                          session.templateEmployeeId!,
                          session.templateEmployeeId,
                        );
                  }
                } else if (value == 4) {
                  ref
                      .read(sessionServiceProvider)
                      .completeSession(
                        session.clientId,
                        timeSlotId,
                        session.employeeId,
                      );
                }
              },
              itemBuilder: (context) => [
                // 1. Mark as Completed (New)
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
        return const Color(0xFFFEF2F2);
      case SessionType.completed:
        return const Color(0xFFF0FDF4); // Light green background
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
}
