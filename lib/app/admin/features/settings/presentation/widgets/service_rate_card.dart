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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: rate.isActive ? Colors.grey.shade200 : Colors.red.shade100,
        ),
      ),
      color: rate.isActive ? Colors.white : Colors.red.withOpacity(0.02),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rate.isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rate.isActive ? 'ACTIVE' : 'ARCHIVED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: rate.isActive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
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
                if (rate.isActive) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    height: 40,
                    child: Text('Edit Rate'),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    height: 40,
                    child: Text('Archive'),
                  ),
                ] else ...[
                  const PopupMenuItem(
                    value: 'unarchive',
                    height: 40,
                    child: Text('Restore'),
                  ),
                ],
                const PopupMenuItem(
                  value: 'delete',
                  height: 40,
                  child: Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => EditServiceRateDialog(rate: rate),
        );
        break;
      case 'archive':
        _showConfirm(
          context,
          ref,
          'Archive Rate',
          'Hide this rate from billing?',
          () {
            ref.read(serviceRateServiceProvider).archiveRate(rate.id);
          },
        );
        break;
      case 'unarchive':
        _showConfirm(
          context,
          ref,
          'Restore Rate',
          'Make this rate active again?',
          () {
            ref.read(serviceRateServiceProvider).unarchiveRate(rate.id);
          },
        );
        break;
      case 'delete':
        _showConfirm(
          context,
          ref,
          'Delete Permanently',
          'Warning: This may affect historical billing calculations!',
          () {
            ref.read(serviceRateServiceProvider).deleteRatePermanently(rate.id);
          },
          isDanger: true,
        );
        break;
    }
  }

  void _showConfirm(
    BuildContext context,
    WidgetRef ref,
    String title,
    String msg,
    VoidCallback onConfirm, {
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : null,
              foregroundColor: isDanger ? Colors.white : null,
            ),
            child: Text(title),
          ),
        ],
      ),
    );
  }
}
