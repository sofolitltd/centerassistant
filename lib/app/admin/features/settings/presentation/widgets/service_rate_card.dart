import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/service_rate.dart';
import '/core/providers/service_rate_providers.dart';
import 'edit_service_rate_dialog.dart';

class ServiceRateCard extends ConsumerWidget {
  final ServiceRate rate;
  const ServiceRateCard({required this.rate, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = _getStatus();
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == 'Expired'
              ? Colors.red.shade100
              : Colors.grey.shade200,
        ),
      ),
      color: status == 'Expired' ? Colors.red.withOpacity(0.02) : Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rate.serviceType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '৳${rate.hourlyRate.toStringAsFixed(0)} / hour',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Effective: ${DateFormat('dd MMM yyyy').format(rate.effectiveDate)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (rate.endDate != null)
                  Text(
                    'Ends: ${DateFormat('dd MMM yyyy').format(rate.endDate!)}',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical, size: 18),
              onSelected: (val) => _handleAction(context, ref, val),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  height: 40,
                  child: Text('Edit Rate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  height: 40,
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      rate.effectiveDate.year,
      rate.effectiveDate.month,
      rate.effectiveDate.day,
    );

    if (start.isAfter(today)) return 'Upcoming';
    if (rate.endDate != null &&
        DateTime(
          rate.endDate!.year,
          rate.endDate!.month,
          rate.endDate!.day,
        ).isBefore(today)) {
      return 'Expired';
    }
    return 'Active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green.shade700;
      case 'Upcoming':
        return Colors.blue.shade700;
      case 'Expired':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'edit') {
      showDialog(
        context: context,
        builder: (context) => EditServiceRateDialog(rate: rate),
      );
    } else if (action == 'delete') {
      _showDeleteConfirm(context, ref);
    }
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rate'),
        content: const Text(
          'Warning: This may affect historical billing calculations!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(serviceRateServiceProvider).deleteRate(rate.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
