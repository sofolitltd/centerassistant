import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/models/transaction.dart';
import '/core/providers/billing_providers.dart';

class BillingHistoryTab extends ConsumerWidget {
  final Client client;
  final AsyncValue<List<ClientTransaction>> transactionsAsync;

  const BillingHistoryTab({
    super.key,
    required this.client,
    required this.transactionsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Column(
          children: [
            // Responsive Top Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isMobile
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBalanceCard(
                          context,
                          'Wallet Balance ',
                          client.walletBalance,
                          Colors.blue.shade800,
                          LucideIcons.wallet,
                        ),
                        const SizedBox(height: 12),
                        _buildBalanceCard(
                          context,
                          'Security Deposit',
                          client.securityDeposit,
                          Colors.orange.shade800,
                          LucideIcons.shieldCheck,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildAddButton(context, ref),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            context,
                            'Wallet Balance (Prepaid)',
                            client.walletBalance,
                            Colors.blue.shade800,
                            LucideIcons.wallet,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBalanceCard(
                            context,
                            'Security Deposit',
                            client.securityDeposit,
                            Colors.orange.shade800,
                            LucideIcons.shieldCheck,
                          ),
                        ),
                        const SizedBox(width: 24),
                        _buildAddButton(context, ref),
                      ],
                    ),
            ),

            const Divider(height: 1),

            // Transaction List
            Expanded(
              child: transactionsAsync.when(
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
                          'Detailed History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.grey.shade50,
                                ),
                                headingRowHeight: 40,
                                dataRowMaxHeight: 52,
                                dataRowMinHeight: 48,
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Amount')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: txs.map((tx) {
                                  final isDebit = tx.amount < 0;
                                  Color amountColor = isDebit
                                      ? Colors.red
                                      : Colors.green.shade700;
                                  if (tx.type == TransactionType.adjustment) {
                                    amountColor = Colors.orange.shade800;
                                  }

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          DateFormat(
                                            'dd-MM-yy',
                                          ).format(tx.timestamp),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(
                                              tx.type,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            tx.type.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getTypeColor(tx.type),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                '${tx.duration}h @ ৳${NumberFormat('#,###').format(tx.rateAtTime)}',
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
                                          '${isDebit ? "" : "+"} ৳ ${NumberFormat('#,###').format(tx.amount.abs())}',
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
                                              onPressed: () => _showEditDialog(
                                                context,
                                                ref,
                                                tx,
                                              ),
                                              icon: const Icon(
                                                LucideIcons.edit,
                                                color: Colors.blueGrey,
                                                size: 16,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _showDeleteConfirm(
                                                    context,
                                                    ref,
                                                    tx,
                                                  ),
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
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showAddTransactionDialog(context, ref),
      icon: const Icon(LucideIcons.plusCircle, size: 18),
      label: const Text('Add Transaction'),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final currencyFormat = NumberFormat('#,###');
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '৳ ${currencyFormat.format(amount)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.prepaid:
        return Colors.green.shade700;
      case TransactionType.deposit:
        return Colors.red.shade700;
      case TransactionType.adjustment:
        return Colors.orange.shade800;
      case TransactionType.refund:
        return Colors.blue;
    }
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final refController = TextEditingController();
    TransactionType selectedType = TransactionType.prepaid;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 350),
              child: Row(
                children: [
                  const Text('Add Transaction'),
                  const Spacer(),

                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
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
                  child: DropdownButtonFormField<TransactionType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type',
                      border: OutlineInputBorder(),
                    ),
                    items: TransactionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.name[0].toUpperCase() + type.name.substring(1),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
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
                const SizedBox(height: 16),
                TextField(
                  controller: refController,
                  decoration: const InputDecoration(
                    labelText: 'Reference/Note',
                    hintText: 'e.g. Bkash #12345',
                    border: OutlineInputBorder(),
                  ),
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
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;

                  if (selectedType == TransactionType.prepaid) {
                    await ref
                        .read(billingServiceProvider)
                        .addPayment(
                          client: client,
                          amount: amount,
                          description: refController.text.isEmpty
                              ? 'Prepaid Payment'
                              : refController.text,
                        );
                  } else if (selectedType == TransactionType.deposit) {
                    await ref
                        .read(billingServiceProvider)
                        .addSecurityDeposit(
                          client: client,
                          amount: amount,
                          description: refController.text.isEmpty
                              ? 'Security Deposit'
                              : refController.text,
                        );
                  } else if (selectedType == TransactionType.refund) {
                    await ref
                        .read(billingServiceProvider)
                        .addRefund(
                          client: client,
                          amount: amount,
                          description: refController.text.isEmpty
                              ? 'Refund Processed'
                              : refController.text,
                        );
                  } else if (selectedType == TransactionType.adjustment) {
                    await ref
                        .read(billingServiceProvider)
                        .applyAdjustment(
                          client: client,
                          amount: amount,
                          description: refController.text.isEmpty
                              ? 'Deposit Adjustment to Wallet'
                              : refController.text,
                        );
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Add Transaction'),
              ),
            ],
          );
        },
      ),
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
    TransactionType selectedType = tx.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Transaction'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 16),
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
                    final signedAmount = tx.amount < 0 ? -newAmount : newAmount;
                    await ref
                        .read(billingServiceProvider)
                        .updateTransaction(
                          oldTx: tx,
                          newAmount: signedAmount,
                          newDescription: descController.text,
                          newType: selectedType,
                        );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
