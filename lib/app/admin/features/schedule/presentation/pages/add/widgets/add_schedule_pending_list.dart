import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';
import '/core/models/session.dart';

class AddSchedulePendingList extends StatelessWidget {
  final List<ServiceDetail> pendingServices;
  final Future<Employee?> Function(String) getEmployee;
  final String Function(String) formatTimeToAmPm;
  final Function(int) onRemoveService;

  const AddSchedulePendingList({
    super.key,
    required this.pendingServices,
    required this.getEmployee,
    required this.formatTimeToAmPm,
    required this.onRemoveService,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingServices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          spacing: 8,
          mainAxisAlignment: .center,
          children: [
            Icon(LucideIcons.calendarX, size: 24, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No services added. Add a service by + button',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(), // Name
                      1: IntrinsicColumnWidth(), // Service
                      2: IntrinsicColumnWidth(), // Start
                      3: IntrinsicColumnWidth(), // End
                      4: IntrinsicColumnWidth(), // Type
                      5: IntrinsicColumnWidth(), // Action
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    children: [
                      // Header
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        children: [
                          _buildHeaderCell('Name'),
                          _buildHeaderCell('Service'),
                          _buildHeaderCell('Start'),
                          _buildHeaderCell('End'),
                          _buildHeaderCell('Type'),
                          _buildHeaderCell('Action'),
                        ],
                      ),
                      // Data Rows
                      ...pendingServices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final service = entry.value;

                        return TableRow(
                          children: [
                            // Name (Employee)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: FutureBuilder<Employee?>(
                                future: getEmployee(service.employeeId),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data?.name ?? '...',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Service
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(service.type),
                            ),
                            // Start
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(formatTimeToAmPm(service.startTime)),
                            ),
                            // End
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(formatTimeToAmPm(service.endTime)),
                            ),
                            // Type
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                service.isInclusive ? "INCLUSIVE" : "EXCLUSIVE",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: service.isInclusive
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                            // Action
                            Center(
                              child: IconButton(
                                icon: const Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => onRemoveService(index),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }
}
