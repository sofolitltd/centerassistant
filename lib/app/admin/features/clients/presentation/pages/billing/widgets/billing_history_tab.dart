import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/transaction.dart';
import '/core/providers/billing_providers.dart';

class BillingHistoryTab extends ConsumerWidget {
  final AsyncValue<List<ClientTransaction>> transactionsAsync;

  const BillingHistoryTab({super.key, required this.transactionsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat('#,###');

    return transactionsAsync.when(
      data: (txs) {
        if (txs.isEmpty) {
          return _buildEmptyState('No transaction history found.');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: SizedBox(
                  width: double.maxFinite,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade50,
                    ),
                    headingRowHeight: 40,
                    dataRowMaxHeight: 52,
                    dataRowMinHeight: 48,
                    columnSpacing: 24,
                    border: TableBorder.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Amount',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Action',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: txs.map((tx) {
                      final isDebit = tx.amount < 0;

                      // Custom color logic based on requirements
                      Color amountColor;
                      if (isDebit) {
                        amountColor = Colors.red;
                      } else if (tx.type == TransactionType.adjustment) {
                        amountColor = Colors.orange.shade800;
                      } else {
                        amountColor = Colors.green.shade700;
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(DateFormat('dd-MM-yy').format(tx.timestamp)),
                          ),
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (tx.duration != null)
                                  Text(
                                    '${tx.duration}h @ ৳${currencyFormat.format(tx.rateAtTime)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '${isDebit ? "" : "+"} ৳ ${currencyFormat.format(tx.amount.abs())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: amountColor,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              spacing: 8,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _showEditDialog(context, ref, tx);
                                  },
                                  icon: const Icon(
                                    LucideIcons.edit,
                                    color: Colors.blueGrey,
                                    size: 16,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _showDeleteConfirm(context, ref, tx);
                                  },
                                  icon: const Icon(
                                    LucideIcons.trash,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ClientTransaction tx,
  ) {
    final amountController = TextEditingController(
      text: tx.amount.abs().toStringAsFixed(0),
    );
    final descController = TextEditingController(text: tx.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null) {
                // Keep the sign of the original transaction
                final signedAmount = tx.amount < 0 ? -newAmount : newAmount;
                await ref
                    .read(billingServiceProvider)
                    .updateTransaction(
                      oldTx: tx,
                      newAmount: signedAmount,
                      newDescription: descController.text,
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    ClientTransaction tx,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'This will revert the balance update associated with this transaction. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(billingServiceProvider).deleteTransaction(tx);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
