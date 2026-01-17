import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';

class BillingDepositTab extends StatefulWidget {
  final Client client;
  final TextEditingController amountController;
  final Function(Client, double, String) onDeposit;
  final Function(Client, double, String) onPayment;

  const BillingDepositTab({
    super.key,
    required this.client,
    required this.amountController,
    required this.onDeposit,
    required this.onPayment,
  });

  @override
  State<BillingDepositTab> createState() => _BillingDepositTabState();
}

class _BillingDepositTabState extends State<BillingDepositTab> {
  final _descriptionController = TextEditingController();
  String _selectedType = 'Prepaid'; // Default type

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const .all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Balance Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceCard(
                      'Prepaid Balance',
                      '৳ ${widget.client.walletBalance.toStringAsFixed(0)}',
                      Colors.green,
                      LucideIcons.wallet,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBalanceCard(
                      'Security Deposit',
                      '৳ ${widget.client.securityDeposit.toStringAsFixed(0)}',
                      Colors.orange.shade800,
                      LucideIcons.shieldCheck,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionCard(
                'Add Funds',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: widget.amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixText: '৳ ',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 13,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Prepaid',
                                  child: Text('Prepaid Payment'),
                                ),
                                DropdownMenuItem(
                                  value: 'Deposit',
                                  child: Text('Security Deposit'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedType = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reference (Cash, Card, Bank, Bkash etc.)',
                        hintText: 'Please mention the source of funds.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleAction,
                        icon: const Icon(LucideIcons.plusCircle),
                        label: Text(
                          'Add ${_selectedType == 'Prepaid' ? 'Payment' : 'Deposit'}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'Prepaid'
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedType == 'Prepaid'
                          ? 'Payments will be added to the active balance for billing.'
                          : 'Security deposits are held separately and not used for regular billing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction() async {
    final amount = double.tryParse(widget.amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final note = _descriptionController.text.trim();
    final typeLabel = _selectedType == 'Prepaid' ? 'Payment' : 'Deposit';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $typeLabel'),
        content: Text(
          'Are you sure you want to add ৳${amount.toStringAsFixed(0)} as a $typeLabel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedType == 'Prepaid'
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (_selectedType == 'Prepaid') {
        widget.onPayment(
          widget.client,
          amount,
          note.isEmpty ? 'Prepaid Payment' : note,
        );
      } else {
        widget.onDeposit(
          widget.client,
          amount,
          note.isEmpty ? 'Security Deposit' : note,
        );
      }
      _descriptionController.clear();
    }
  }

  Widget _buildBalanceCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(icon, size: 20, color: color),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            content,
          ],
        ),
      ),
    );
  }
}
