import 'dart:ui';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/providers/client_providers.dart';

class ClientPage extends ConsumerWidget {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                        Text('Clients', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Client Directory',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/clients/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Client'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table Card
            Expanded(
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: clientsAsync.when(
                  data: (clients) {
                    if (clients.isEmpty) {
                      return const Center(child: Text('No clients found.'));
                    }

                    // Reverse numeric sort by clientId
                    final sortedClients = List<Client>.from(clients)
                      ..sort((a, b) {
                        try {
                          final idA = int.parse(a.clientId);
                          final idB = int.parse(b.clientId);
                          return idB.compareTo(idA);
                        } catch (_) {
                          return b.clientId.compareTo(a.clientId);
                        }
                      });

                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                        },
                      ),
                      child: DataTable2(
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        minWidth: 1000,
                        headingRowColor: WidgetStateProperty.all(
                          theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        border: TableBorder.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        columns: const [
                          DataColumn2(
                            label: Text(
                              'ID',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            headingRowAlignment: MainAxisAlignment.center,
                            fixedWidth: 24,
                          ),
                          DataColumn2(
                            label: Text(
                              'Client Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            size: ColumnSize.L,
                          ),
                          DataColumn2(
                            label: Text(
                              'Nick Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn2(
                            label: Text(
                              'Gender',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            fixedWidth: 100,
                          ),
                          DataColumn2(
                            label: Text(
                              'Age',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            fixedWidth: 80,
                          ),
                          DataColumn2(
                            label: Text(
                              'Contact',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            size: ColumnSize.M,
                          ),
                          DataColumn2(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            fixedWidth: 100,
                          ),
                        ],
                        rows: sortedClients.map((client) {
                          return DataRow2(
                            onTap: () =>
                                context.go('/admin/clients/${client.id}'),
                            cells: [
                              DataCell(
                                Center(
                                  child: Text(
                                    client.clientId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundImage: client.image.isNotEmpty
                                          ? NetworkImage(client.image)
                                          : null,
                                      child: client.image.isEmpty
                                          ? const Icon(Icons.person, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        client.name,
                                        style: const TextStyle(
                                          // fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(client.nickName)),
                              DataCell(Text(client.gender.toUpperCase())),
                              DataCell(
                                Text('${_calculateAge(client.dateOfBirth)} Y'),
                              ),
                              DataCell(Text(client.mobileNo)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.edit,
                                        size: 16,
                                      ),
                                      onPressed: () => context.go(
                                        '/admin/clients/${client.id}/edit',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _showDeleteConfirmDialog(
                                        context,
                                        ref,
                                        client,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(clientServiceProvider).deleteClient(client.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
