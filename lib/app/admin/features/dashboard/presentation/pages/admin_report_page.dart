import 'dart:ui' as pw;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/invoice_snapshot.dart';
import '/core/models/transaction.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/invoice_snapshot_providers.dart';

class AdminReportPage extends ConsumerWidget {
  const AdminReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(clientsProvider);
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());

    final monthlySnapshotsAsync = ref.watch(
      allInvoiceSnapshotsByMonthProvider((
        monthKey: monthKey,
        type: InvoiceType.post,
      )),
    );
    final monthlySnapshotsByRangeAsync = ref.watch(
      allInvoiceSnapshotsByRangeProvider(6),
    );
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),

            // Financial KPIs
            _buildKpiGrid(context, monthlySnapshotsAsync, clientsAsync),
            const SizedBox(height: 32),

            // Revenue Growth Chart
            _buildSectionTitle(
              context,
              'Strategic Financial Growth (Realized Revenue)',
              icon: LucideIcons.trendingUp,
            ),
            const SizedBox(height: 16),
            _buildRevenueChart(context, monthlySnapshotsByRangeAsync),

            const SizedBox(height: 32),

            // Latest Transactions
            _buildSectionTitle(
              context,
              'Latest Transactions Activity',
              icon: LucideIcons.history,
            ),
            const SizedBox(height: 16),
            _buildRecentTransactions(context, transactionsAsync, clientsAsync),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Reports',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        Text(
          'Detailed revenue and transaction insights',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    AsyncValue<List<InvoiceSnapshot>> snapshotsAsync,
    AsyncValue<dynamic> clientsAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000 ? 4 : 2;
        return MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: 4,
          itemBuilder: (context, index) {
            if (index == 0) {
              return snapshotsAsync.when(
                data: (snapshots) {
                  final total = snapshots.fold<double>(
                    0,
                    (sum, s) => sum + s.totalAmount,
                  );
                  return _buildKpiCard(
                    context,
                    'Monthly Revenue',
                    '৳${NumberFormat('#,##,###').format(total)}',
                    LucideIcons.banknote,
                    Colors.black,
                    'Realized this month',
                  );
                },
                loading: () => _buildKpiCard(
                  context,
                  'Monthly Revenue',
                  '...',
                  LucideIcons.banknote,
                  Colors.black,
                  'Loading...',
                ),
                error: (_, __) => _buildKpiCard(
                  context,
                  'Monthly Revenue',
                  '৳0',
                  LucideIcons.banknote,
                  Colors.black,
                  'Error',
                ),
              );
            }
            if (index == 1) {
              return clientsAsync.when(
                data: (clients) {
                  final totalDue = (clients as List).fold<double>(
                    0,
                    (sum, c) =>
                        c.walletBalance < 0 ? sum + c.walletBalance.abs() : sum,
                  );
                  return _buildKpiCard(
                    context,
                    'Total Outstanding Due',
                    '৳${NumberFormat('#,##,###').format(totalDue)}',
                    LucideIcons.alertCircle,
                    Colors.red,
                    'Collectable from clients',
                  );
                },
                loading: () => _buildKpiCard(
                  context,
                  'Total Outstanding Due',
                  '...',
                  LucideIcons.alertCircle,
                  Colors.red,
                  'Loading...',
                ),
                error: (_, _) => _buildKpiCard(
                  context,
                  'Total Outstanding Due',
                  '৳0',
                  LucideIcons.alertCircle,
                  Colors.red,
                  'Error',
                ),
              );
            }
            if (index == 2) {
              return clientsAsync.when(
                data: (clients) {
                  final totalAdvance = (clients as List).fold<double>(
                    0,
                    (sum, c) =>
                        c.walletBalance > 0 ? sum + c.walletBalance : sum,
                  );
                  return _buildKpiCard(
                    context,
                    'Total Advance Balance',
                    '৳${NumberFormat('#,##,###').format(totalAdvance)}',
                    LucideIcons.wallet,
                    Colors.blueAccent,
                    'Prepaid by clients',
                  );
                },
                loading: () => _buildKpiCard(
                  context,
                  'Total Advance Balance',
                  '...',
                  LucideIcons.wallet,
                  Colors.blueAccent,
                  'Loading...',
                ),
                error: (_, __) => _buildKpiCard(
                  context,
                  'Total Advance Balance',
                  '0',
                  LucideIcons.wallet,
                  Colors.blueAccent,
                  'Error',
                ),
              );
            }
            return clientsAsync.when(
              data: (clients) {
                final totalDeposit = (clients as List).fold<double>(
                  0,
                  (sum, c) => sum + c.securityDeposit,
                );
                return _buildKpiCard(
                  context,
                  'Total Security Deposit',
                  '৳${NumberFormat('#,##,###').format(totalDeposit)}',
                  LucideIcons.shieldCheck,
                  Colors.orange.shade800,
                  'Held security funds',
                );
              },
              loading: () => _buildKpiCard(
                context,
                'Total Security Deposit',
                '...',
                LucideIcons.shieldCheck,
                Colors.orange.shade800,
                'Loading...',
              ),
              error: (_, __) => _buildKpiCard(
                context,
                'Total Security Deposit',
                '0',
                LucideIcons.shieldCheck,
                Colors.orange.shade800,
                'Error',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRevenueChart(
    BuildContext context,
    AsyncValue<List<InvoiceSnapshot>> snapshotsByRangeAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        height: 350,
        padding: const EdgeInsets.fromLTRB(16, 40, 24, 16),
        child: snapshotsByRangeAsync.when(
          data: (snapshots) {
            final Map<String, double> monthlyRevenue = {};
            final now = DateTime.now();
            for (int i = 0; i < 6; i++) {
              final date = DateTime(now.year, now.month - i);
              final monthKey = DateFormat('yyyy-MM').format(date);
              monthlyRevenue[monthKey] = 0.0;
            }
            for (var s in snapshots) {
              if (monthlyRevenue.containsKey(s.monthKey)) {
                monthlyRevenue[s.monthKey] =
                    monthlyRevenue[s.monthKey]! + s.totalAmount;
              }
            }
            final sortedMonths = monthlyRevenue.keys.toList()..sort();
            final List<BarChartGroupData> barGroups = [];
            double maxVal = 0;
            for (int i = 0; i < sortedMonths.length; i++) {
              final revenue = monthlyRevenue[sortedMonths[i]]!;
              if (revenue > maxVal) maxVal = revenue;
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: revenue,
                      color: Colors.blueAccent,
                      width: 22,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }
            double interval = (maxVal / 5);
            if (interval < 1000) interval = 1000;
            interval = (interval / 500).ceil() * 500.0;

            return BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedMonths.length) {
                          final monthDate = DateTime.parse(
                            '${sortedMonths[value.toInt()]}-01',
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM yy').format(monthDate),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 65,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '৳${NumberFormat('#,###').format(value.toInt())}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                maxY: (maxVal * 1.15).ceilToDouble(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Error loading chart')),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<ClientTransaction>> transactionsAsync,
    AsyncValue<dynamic> clientsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty)
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: Text('No recent transactions.')),
            );
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 10 ? 10 : transactions.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isCredit = tx.type == TransactionType.prepaid;
              final client = (clientsAsync.value as List?)
                  ?.where((c) => c.id == tx.clientId)
                  .firstOrNull;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: (isCredit ? Colors.black : Colors.blue)
                      .withOpacity(0.1),
                  child: Icon(
                    isCredit ? LucideIcons.arrowDownLeft : LucideIcons.zap,
                    size: 18,
                    color: isCredit ? Colors.black : Colors.blue,
                  ),
                ),
                title: Text(
                  '${client?.name ?? "Unknown"} - ${tx.description}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, hh:mm a').format(tx.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Text(
                  '${isCredit ? "+" : "-"} ৳${NumberFormat('#,###').format(tx.amount.abs())}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Center(child: Text('Error loading activity')),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
