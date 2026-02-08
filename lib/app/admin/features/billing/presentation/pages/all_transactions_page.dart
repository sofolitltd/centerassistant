import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/transaction.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_providers.dart';

class AllTransactionsPage extends ConsumerStatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  ConsumerState<AllTransactionsPage> createState() =>
      _AllTransactionsPageState();
}

class _AllTransactionsPageState extends ConsumerState<AllTransactionsPage> {
  String _searchQuery = '';
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumbs(context),
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 32),

              // Responsive Summary Section (Masonry Grid)
              transactionsAsync.when(
                data: (txs) => _buildSummarySection(txs),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error calculating stats: $e'),
              ),

              const SizedBox(height: 32),

              // Responsive Filter Bar
              _buildFilterBar(),

              const SizedBox(height: 16),

              // Scrollable Data Table
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: transactionsAsync.when(
                  data: (txs) {
                    final filtered = _filterTransactions(
                      txs,
                      clientsAsync.value,
                    );
                    if (filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(
                          child: Text('No transactions match your filters.'),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 800),
                        child: _buildTransactionTable(
                          filtered,
                          clientsAsync.value,
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading transactions: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/admin/dashboard'),
          child: const Text(
            'Admin',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        InkWell(
          onTap: () => context.go('/admin/dashboard'),
          child: const Text(
            'Dashboard',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        const Text(
          'Transactions',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Comprehensive history of all financial activities.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummarySection(List<ClientTransaction> txs) {
    final now = DateTime.now();
    final currentMonthTxs = txs
        .where(
          (t) => t.timestamp.month == now.month && t.timestamp.year == now.year,
        )
        .toList();

    final totalPrepaid = currentMonthTxs
        .where((t) => t.type == TransactionType.prepaid)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalDeposit = currentMonthTxs
        .where((t) => t.type == TransactionType.deposit)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalRefunds = currentMonthTxs
        .where((t) => t.type == TransactionType.refund)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    final netCashFlow = (totalPrepaid + totalDeposit) - totalRefunds;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Aligned with Dashboard: 4 items on LG (>1000), 2 otherwise
        int crossAxisCount = constraints.maxWidth > 1000 ? 4 : 2;

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: 4,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildStatCard(
                'Prepaid Collected',
                totalPrepaid,
                LucideIcons.wallet,
                Colors.green,
              );
            } else if (index == 1) {
              return _buildStatCard(
                'Security Deposit',
                totalDeposit,
                LucideIcons.shieldCheck,
                Colors.orange,
              );
            } else if (index == 2) {
              return _buildStatCard(
                'Total Refunds',
                totalRefunds,
                LucideIcons.arrowUpRight,
                Colors.red,
              );
            } else {
              return _buildStatCard(
                'Net Cash Flow',
                netCashFlow,
                LucideIcons.activity,
                Colors.blueAccent,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '৳${NumberFormat('#,###').format(value)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 350,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search client...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              Container(
                width: isMobile ? double.infinity : 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TransactionType?>(
                    value: _selectedType,
                    isExpanded: true,
                    isDense: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    hint: const Text('Filter Type'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...TransactionType.values.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.name[0].toUpperCase() + t.name.substring(1),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ClientTransaction> _filterTransactions(
    List<ClientTransaction> txs,
    dynamic clients,
  ) {
    return txs.where((tx) {
      bool matchesType = _selectedType == null || tx.type == _selectedType;
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty && clients != null) {
        final client = (clients as List)
            .where((c) => c.id == tx.clientId)
            .firstOrNull;
        matchesSearch =
            client?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ??
            false;
      }
      return matchesType && matchesSearch;
    }).toList();
  }

  Widget _buildTransactionTable(List<ClientTransaction> txs, dynamic clients) {
    return DataTable(
      horizontalMargin: 24,
      columnSpacing: 32,
      columns: const [
        DataColumn(
          label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows: txs.map((tx) {
        final client = (clients as List?)
            ?.where((c) => c.id == tx.clientId)
            .firstOrNull;
        final isDebit = tx.amount < 0;
        return DataRow(
          cells: [
            DataCell(Text(DateFormat('MMM dd, hh:mm a').format(tx.timestamp))),
            DataCell(
              InkWell(
                onTap: () => context.go('/admin/clients/${tx.clientId}'),
                child: Text(
                  client?.name ?? 'Unknown Client',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            DataCell(_buildTypeBadge(tx.type)),
            DataCell(Text(tx.description)),
            DataCell(
              Text(
                '৳${NumberFormat('#,###').format(tx.amount.abs())}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDebit ? Colors.black87 : Colors.green,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTypeBadge(TransactionType type) {
    Color color = Colors.grey;
    if (type == TransactionType.prepaid) {
      color = Colors.green;
    } else if (type == TransactionType.deposit)
      color = Colors.orange;
    else if (type == TransactionType.refund)
      color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
