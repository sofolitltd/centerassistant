// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:lucide_icons/lucide_icons.dart';
//
// import '/core/models/client.dart';
// import '/core/models/employee.dart';
// import '/core/models/session.dart';
// import '/core/providers/client_providers.dart';
// import '/core/providers/employee_providers.dart';
// import '/core/providers/session_providers.dart';
//
// class AddSessionDialog extends ConsumerStatefulWidget {
//   final String timeSlotId;
//
//   const AddSessionDialog({super.key, required this.timeSlotId});
//
//   @override
//   ConsumerState<AddSessionDialog> createState() => _AddSessionDialogState();
// }
//
// class _AddSessionDialogState extends ConsumerState<AddSessionDialog> {
//   Client? _selectedClient;
//   Employee? _builderEmployee;
//   String _builderServiceType = 'ABA';
//   final _durationController = TextEditingController(text: '1.0');
//   final List<ServiceDetail> _pendingServices = [];
//   SessionType _sessionType = SessionType.extra;
//
//   @override
//   void dispose() {
//     _durationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final employeesAsync = ref.watch(employeesProvider);
//     final schedulableDeptsAsync = ref.watch(schedulableDepartmentsProvider);
//     final selectedDate = ref.watch(selectedDateProvider);
//
//     return AlertDialog(
//       title: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             'Session Configuration',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//       content: SizedBox(
//         width: 500,
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 1. Client Selection
//               const Text(
//                 '1. Target Client',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//               ),
//               const SizedBox(height: 8),
//               ref
//                   .watch(clientsProvider)
//                   .when(
//                     data: (clients) => DropdownButtonFormField<Client>(
//                       isExpanded: true,
//                       hint: const Text('Select Client'),
//                       value: _selectedClient,
//                       onChanged: (c) => setState(() => _selectedClient = c),
//                       items: clients
//                           .map(
//                             (c) =>
//                                 DropdownMenuItem(value: c, child: Text(c.name)),
//                           )
//                           .toList(),
//                       decoration: _inputDecoration(),
//                     ),
//                     loading: () => const LinearProgressIndicator(),
//                     error: (_, __) => const Text('Error loading clients'),
//                   ),
//               const SizedBox(height: 24),
//
//               // 2. Service Builder Section
//               const Text(
//                 '2. Service Builder (Multi-Therapist)',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//               ),
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.03),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.withOpacity(0.1)),
//                 ),
//                 child: Column(
//                   children: [
//                     employeesAsync.when(
//                       data: (employees) => schedulableDeptsAsync.when(
//                         data: (schedulableDepts) {
//                           // TODO: Filter out busy employees if needed for the specific date
//                           final available = employees
//                               .where(
//                                 (e) => schedulableDepts.contains(e.department),
//                               )
//                               .toList();
//                           return DropdownButtonFormField<Employee>(
//                             isExpanded: true,
//                             hint: const Text('Select Therapist'),
//                             value: _builderEmployee,
//                             onChanged: (e) =>
//                                 setState(() => _builderEmployee = e),
//                             items: available
//                                 .map(
//                                   (e) => DropdownMenuItem(
//                                     value: e,
//                                     child: Text(e.name),
//                                   ),
//                                 )
//                                 .toList(),
//                             decoration: _inputDecoration(label: 'Therapist'),
//                           );
//                         },
//                         loading: () => const SizedBox(),
//                         error: (_, __) => const SizedBox(),
//                       ),
//                       loading: () => const SizedBox(),
//                       error: (_, __) => const SizedBox(),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: DropdownButtonFormField<String>(
//                             value: _builderServiceType,
//                             onChanged: (v) =>
//                                 setState(() => _builderServiceType = v!),
//                             items: ['ABA', 'SLT', 'OT', 'PT', 'Counselling']
//                                 .map(
//                                   (s) => DropdownMenuItem(
//                                     value: s,
//                                     child: Text(s),
//                                   ),
//                                 )
//                                 .toList(),
//                             decoration: _inputDecoration(label: 'Service'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           flex: 2,
//                           child: TextField(
//                             controller: _durationController,
//                             keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true,
//                             ),
//                             decoration: _inputDecoration(
//                               label: 'Hours',
//                               suffix: 'h',
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton.icon(
//                         onPressed: _addServiceToPending,
//                         icon: const Icon(LucideIcons.plus, size: 16),
//                         label: const Text('Add to List'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue.shade700,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // 3. List of Added Services
//               if (_pendingServices.isNotEmpty) ...[
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Assigned Therapists:',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//                 ),
//                 const SizedBox(height: 8),
//                 ListView.separated(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _pendingServices.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 8),
//                   itemBuilder: (context, index) {
//                     final service = _pendingServices[index];
//                     return FutureBuilder<Employee?>(
//                       future: _getEmployee(service.employeeId),
//                       builder: (context, snapshot) => Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(6),
//                           border: Border.all(color: Colors.grey.shade200),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(
//                               LucideIcons.user,
//                               size: 14,
//                               color: Colors.blue,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 '${snapshot.data?.name ?? '...'} | ${service.type} (${service.duration}h)',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(
//                                 LucideIcons.trash2,
//                                 size: 16,
//                                 color: Colors.red,
//                               ),
//                               onPressed: () => setState(
//                                 () => _pendingServices.removeAt(index),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//
//               const SizedBox(height: 24),
//               const Text(
//                 '3. Booking Details',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<SessionType>(
//                 value: _sessionType,
//                 onChanged: (v) => setState(() => _sessionType = v!),
//                 items:
//                     [SessionType.regular, SessionType.extra, SessionType.makeup]
//                         .map(
//                           (t) => DropdownMenuItem(
//                             value: t,
//                             child: Text(t.name.toUpperCase()),
//                           ),
//                         )
//                         .toList(),
//                 decoration: _inputDecoration(label: 'Session Type'),
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: (_selectedClient == null || _pendingServices.isEmpty)
//               ? null
//               : _handleSave,
//           child: const Text('Book Session'),
//         ),
//       ],
//     );
//   }
//
//   void _addServiceToPending() {
//     if (_builderEmployee == null) return;
//     final dur = double.tryParse(_durationController.text) ?? 1.0;
//     setState(() {
//       _pendingServices.add(
//         ServiceDetail(
//           type: _builderServiceType,
//           duration: dur,
//           employeeId: _builderEmployee!.id,
//         ),
//       );
//       _builderEmployee = null;
//     });
//   }
//
//   Future<void> _handleSave() async {
//     final selectedDate = ref.read(selectedDateProvider);
//     await ref
//         .read(sessionServiceProvider)
//         .bookSession(
//           clientId: _selectedClient!.id,
//           timeSlotId: widget.timeSlotId,
//           sessionType: _sessionType,
//           services: _pendingServices,
//           date: selectedDate,
//         );
//     if (mounted) Navigator.pop(context);
//   }
//
//   Future<Employee?> _getEmployee(String id) async {
//     final employees = ref.read(employeesProvider).value ?? [];
//     return employees.where((e) => e.id == id).firstOrNull;
//   }
//
//   InputDecoration _inputDecoration({String? label, String? suffix}) {
//     return InputDecoration(
//       labelText: label,
//       suffixText: suffix,
//       border: const OutlineInputBorder(),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//     );
//   }
// }
