import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/employee.dart';
import '/core/models/session.dart';

class AddSchedulePendingList extends StatelessWidget {
  final List<ServiceDetail> pendingServices;
  final Future<Employee?> Function(String) getEmployee;
  final String Function(String) formatTimeToAmPm;
  final Function(int) onRemoveService;
  final Function(int, ServiceDetail)? onEditService;

  const AddSchedulePendingList({
    super.key,
    required this.pendingServices,
    required this.getEmployee,
    required this.formatTimeToAmPm,
    required this.onRemoveService,
    this.onEditService,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingServices.isEmpty) {
      return _buildEmptyState();
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
                      2: IntrinsicColumnWidth(), // Time
                      3: FixedColumnWidth(40), // Duration
                      4: IntrinsicColumnWidth(), // Type
                      5: IntrinsicColumnWidth(), // Exc/Inc
                      6: FixedColumnWidth(100), // Action (Edit/Delete)
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    children: [
                      _buildHeader(),
                      ...pendingServices.asMap().entries.map((entry) {
                        return _buildDataRow(entry.key, entry.value);
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

  TableRow _buildHeader() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _buildHeaderCell('Name'),
        _buildHeaderCell('Service'),
        _buildHeaderCell('Time'),
        _buildHeaderCell('Dur.'),
        _buildHeaderCell('Type'),
        _buildHeaderCell('Exc/Inc'),
        _buildHeaderCell('Action', align: TextAlign.center),
      ],
    );
  }

  TableRow _buildDataRow(int index, ServiceDetail service) {
    return TableRow(
      children: [
        // Name
        Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<Employee?>(
            future: getEmployee(service.employeeId),
            builder: (context, snapshot) {
              return Text(
                snapshot.data?.name ?? '...',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        // Service
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(service.type, style: const TextStyle(fontSize: 12)),
        ),
        // Time
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            "${formatTimeToAmPm(service.startTime)} - ${formatTimeToAmPm(service.endTime)}",
            style: const TextStyle(fontSize: 11),
          ),
        ),
        // Duration
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            "${service.duration.toStringAsFixed(1)} h",
            style: const TextStyle(fontSize: 11),
          ),
        ),
        // Type
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildBadge(
            service.sessionType.displayName,
            _getSessionTypeColor(service.sessionType),
          ),
        ),
        // Exc/Inc
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            service.isInclusive ? "Inclusive" : "Exclusive",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: service.isInclusive
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ),
        // Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onEditService != null)
                IconButton(
                  icon: const Icon(LucideIcons.edit2, size: 16),
                  onPressed: () => onEditService!(index, service),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              IconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: () => onRemoveService(index),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const .fromLTRB(6, 4, 6, 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      alignment: .center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSessionTypeColor(SessionType type) {
    switch (type) {
      case SessionType.regular:
        return Colors.blue;
      case SessionType.cover:
        return Colors.orange;
      case SessionType.makeup:
        return Colors.teal;
      case SessionType.extra:
        return Colors.purple;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendarX, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No services added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add services using the + button above',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
