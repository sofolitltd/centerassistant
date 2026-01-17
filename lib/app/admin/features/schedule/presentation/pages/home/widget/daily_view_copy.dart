import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;
import 'package:intl/intl.dart';

import '/core/providers/office_settings_providers.dart';
import '/core/providers/session_providers.dart';
import '../../../widgets/session_card.dart';
import '../schedule_planner_page.dart';

class DailyViewCopy extends ConsumerWidget {
  const DailyViewCopy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleViewProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final closedReasonAsync = ref.watch(isOfficeClosedProvider(selectedDate));

    return scheduleAsync.when(
      data: (view) {
        if (view.timeSlots.isEmpty) {
          return const Center(child: Text('No time slots available'));
        }

        // Sort time slots by start time
        final sortedSlots = List<dynamic>.from(view.timeSlots)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: closedReasonAsync.when(
                data: (reason) {
                  if (reason != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            size: 64,
                            color: Colors.red.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Center Closed: $reason',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No sessions can be scheduled on this day.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(388),
                        border: TableBorder(
                          borderRadius: BorderRadius.circular(4),
                          verticalInside: BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          top: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          right: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          left: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                          bottom: const BorderSide(
                            color: gridBorderColor,
                            width: 1,
                          ),
                        ),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: headerBgColor,
                              border: Border(
                                bottom: BorderSide(
                                  color: gridBorderColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            children: sortedSlots.map((slot) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ' (${slot.label})',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final filter = ref.read(
                                        scheduleFilterProvider,
                                      );
                                      String path =
                                          '/admin/schedule/add?timeSlotId=${slot.id}';
                                      if (filter.clientId != null) {
                                        path += '&clientId=${filter.clientId}';
                                      }
                                      if (filter.employeeId != null) {
                                        path +=
                                            '&employeeId=${filter.employeeId}';
                                      }
                                      context.push(path);
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: Colors.black38,
                                    ),
                                    tooltip: 'Add Session',
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                          TableRow(
                            children: sortedSlots.map((slot) {
                              final sessions =
                                  view.sessionsByTimeSlot[slot.id] ?? [];
                              return Container(
                                color: cellBgColor,
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (sessions.isEmpty)
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 400,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'No sessions scheduled',
                                            style: TextStyle(
                                              color: Colors.black26,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...sessions.map(
                                        (s) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: SessionCard(
                                            session: s,
                                            timeSlotId: slot.id,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _formatTime(String time24h) {
    if (time24h.isEmpty) return '';
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2024, 1, 1, hour, minute);
      return DateFormat.jm().format(dt);
    } catch (e) {
      return time24h;
    }
  }
}

///
///
//
// import 'package:data_table_2/data_table_2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart';
//
// import '/core/models/session.dart';
// import '/core/providers/office_settings_providers.dart';
// import '/core/providers/session_providers.dart';
//
// // --- Updated State Provider using Notifier ---
// class SelectedTimeSlotNotifier extends Notifier<String?> {
//   @override
//   String? build() => null;
//
//   void select(String id) => state = id;
//
//   void initializeIfNull(String id) {
//     if (state == null) {
//       // Use future to avoid 'setstate during build' errors
//       Future.microtask(() => state = id);
//     }
//   }
// }
//
// final selectedTimeSlotIdProvider =
// NotifierProvider<SelectedTimeSlotNotifier, String?>(
//   SelectedTimeSlotNotifier.new,
// );
//
// class DailyView extends ConsumerWidget {
//   const DailyView({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final scheduleAsync = ref.watch(scheduleViewProvider);
//     final selectedDate = ref.watch(selectedDateProvider);
//     final closedReasonAsync = ref.watch(isOfficeClosedProvider(selectedDate));
//     final selectedSlotId = ref.watch(selectedTimeSlotIdProvider);
//
//     return scheduleAsync.when(
//       data: (view) {
//         if (view.timeSlots.isEmpty) {
//           return const Center(child: Text('No time slots available'));
//         }
//
//         // Sort time slots
//         final sortedSlots = List<dynamic>.from(view.timeSlots)
//           ..sort((a, b) => a.startTime.compareTo(b.startTime));
//
//         // Auto-select first slot if none selected
//         if (selectedSlotId == null && sortedSlots.isNotEmpty) {
//           ref
//               .read(selectedTimeSlotIdProvider.notifier)
//               .initializeIfNull(sortedSlots.first.id);
//         }
//
//         return Column(
//           children: [
//             // --- CUSTOM TAB BUTTONS BAR ---
//             _buildTimeTabSlider(context, ref, sortedSlots, selectedSlotId),
//
//             const Divider(height: 1),
//
//             // --- MAIN TABLE CONTENT ---
//             Expanded(
//               child: closedReasonAsync.when(
//                 data: (reason) {
//                   if (reason != null) return _buildClosedView(reason);
//                   return _buildSessionTable(context, ref, view, selectedSlotId);
//                 },
//                 loading: () => const Center(child: CircularProgressIndicator()),
//                 error: (e, _) => Center(child: Text('Error: $e')),
//               ),
//             ),
//           ],
//         );
//       },
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (e, _) => Center(child: Text('Error: $e')),
//     );
//   }
//
//   // Horizontal Tab-like Buttons
//   Widget _buildTimeTabSlider(
//       BuildContext context,
//       WidgetRef ref,
//       List<dynamic> slots,
//       String? activeId,
//       ) {
//     return Container(
//       height: 70,
//       width: double.infinity,
//       color: Colors.white,
//       child: ListView.separated(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         scrollDirection: Axis.horizontal,
//         itemCount: slots.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 12),
//         itemBuilder: (context, index) {
//           final slot = slots[index];
//           final bool isSelected = activeId == slot.id;
//           final String timeRange =
//               "${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}";
//
//           return InkWell(
//             onTap: () =>
//                 ref.read(selectedTimeSlotIdProvider.notifier).select(slot.id),
//             borderRadius: BorderRadius.circular(8),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? Theme.of(context).primaryColor
//                     : Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: isSelected
//                       ? Theme.of(context).primaryColor
//                       : Colors.grey.shade300,
//                 ),
//                 boxShadow: isSelected
//                     ? [
//                   const BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ]
//                     : null,
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 timeRange,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : Colors.black87,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // DataTable2 Implementation
//   Widget _buildSessionTable(
//       BuildContext context,
//       WidgetRef ref,
//       dynamic view,
//       String? selectedId,
//       ) {
//     final sessions = view.sessionsByTimeSlot[selectedId] ?? [];
//
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: DataTable2(
//         columnSpacing: 12,
//         horizontalMargin: 12,
//         minWidth: 1000, // Ensures horizontal scroll on small screens
//         headingRowHeight: 50,
//         headingTextStyle: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Colors.black87,
//         ),
//         headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
//         border: TableBorder.all(color: Colors.grey.shade200, width: 1),
//         columns: const [
//           DataColumn2(label: Text('#'), size: ColumnSize.S, fixedWidth: 50),
//           DataColumn2(label: Text('Name(ID)'), size: ColumnSize.L),
//           DataColumn2(label: Text('Services'), size: ColumnSize.L),
//           DataColumn2(label: Text('Therapist'), size: ColumnSize.M),
//           DataColumn2(label: Text('Hour'), size: ColumnSize.M),
//           DataColumn2(label: Text('Type'), size: ColumnSize.S),
//           DataColumn2(label: Text('Status'), size: ColumnSize.S),
//           DataColumn2(label: Text('Action'), size: ColumnSize.S, numeric: true),
//         ],
//         rows: List<DataRow>.generate(sessions.length, (index) {
//           final s = sessions[index];
//           return DataRow(
//             cells: [
//               DataCell(Text('${index + 1}')),
//               DataCell(
//                 Text(
//                   s.displayFullName,
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//               ),
//               DataCell(Text(s.serviceName)),
//               DataCell(Text(s.therapistName.isEmpty ? '-' : s.therapistName)),
//               DataCell(
//                 Text("${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}"),
//               ),
//               DataCell(Text(_getSessionCategory(s.sessionType))),
//               DataCell(_buildStatusBadge(_getSessionStatus(s.sessionType))),
//               DataCell(
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.edit_outlined, size: 20),
//                       onPressed: () =>
//                           context.push('/admin/schedule/edit/${s.id}'),
//                     ),
//                     IconButton(
//                       icon: const Icon(
//                         Icons.delete_outline,
//                         size: 20,
//                         color: Colors.redAccent,
//                       ),
//                       onPressed: () => _handleDelete(s.id),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         }),
//         empty: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.calendar_today_outlined,
//                 size: 50,
//                 color: Colors.grey.shade300,
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'No sessions scheduled for this time slot',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _getSessionCategory(SessionType type) {
//     switch (type) {
//       case SessionType.regular:
//         return 'Regular';
//       case SessionType.cover:
//         return 'Cover';
//       case SessionType.makeup:
//         return 'Makeup';
//       case SessionType.extra:
//         return 'Extra';
//       default:
//         return 'Regular';
//     }
//   }
//
//   String _getSessionStatus(SessionType type) {
//     switch (type) {
//       case SessionType.completed:
//         return 'Complete';
//       case SessionType.cancelled:
//       case SessionType.cancelledCenter:
//       case SessionType.cancelledClient:
//         return 'Cancel';
//       default:
//         return 'Scheduled';
//     }
//   }
//
//   Widget _buildStatusBadge(String status) {
//     Color color;
//     switch (status.toLowerCase()) {
//       case 'complete':
//         color = Colors.green;
//         break;
//       case 'cancel':
//         color = Colors.red;
//         break;
//       default:
//         color = Colors.blue;
//     }
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withValues(alpha: 0.5)),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildClosedView(String reason) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.lock_clock, size: 80, color: Colors.orange.shade200),
//           const SizedBox(height: 16),
//           Text(
//             'Office Closed: $reason',
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const Text(
//             'Scheduling is disabled for this date.',
//             style: TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTime(String time24h) {
//     if (time24h.isEmpty) return '';
//     try {
//       final parts = time24h.split(':');
//       final hour = int.parse(parts[0]);
//       final minute = int.parse(parts[1]);
//       final dt = DateTime(2024, 1, 1, hour, minute);
//       return DateFormat('h:mm a').format(dt);
//     } catch (e) {
//       return time24h;
//     }
//   }
//
//   void _handleDelete(String id) {
//     // Add delete logic
//   }
// }
