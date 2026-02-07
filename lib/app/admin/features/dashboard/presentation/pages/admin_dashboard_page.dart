import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/invoice_snapshot.dart';
import '/core/models/leave.dart';
import '/core/models/session.dart';
import '/core/models/transaction.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/invoice_snapshot_providers.dart';
import '/core/providers/leave_providers.dart';
import '/core/providers/session_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final todayScheduleAsync = ref.watch(scheduleViewProvider);
    final leavesAsync = ref.watch(allLeavesProvider);
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
    final allMonthlySessionsAsync = ref.watch(allMonthlySessionsProvider);

    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),

            // KPI Grid - Responsive Layout
            _buildKpiGrid(context, monthlySnapshotsAsync, clientsAsync),

            const SizedBox(height: 24),

            // Main Charts & Lists Section
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 1000;
                return Column(
                  children: [
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildLeftColumn(
                              context,
                              ref,
                              transactionsAsync,
                              monthlySnapshotsByRangeAsync,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildRightColumn(
                              context,
                              allMonthlySessionsAsync,
                              todayScheduleAsync,
                              leavesAsync,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildLeftColumn(
                            context,
                            ref,
                            transactionsAsync,
                            monthlySnapshotsByRangeAsync,
                          ),
                          const SizedBox(height: 32),
                          _buildRightColumn(
                            context,
                            allMonthlySessionsAsync,
                            todayScheduleAsync,
                            leavesAsync,
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ClientTransaction>> transactionsAsync,
    AsyncValue<List<InvoiceSnapshot>> monthlySnapshotsByRangeAsync,
  ) {
    return Column(
      children: [
        _buildSectionTitle(
          context,
          'Revenue Performance & Growth Trends',
          icon: LucideIcons.trendingUp,
        ),
        const SizedBox(height: 16),
        _buildRevenueChart(context, ref, monthlySnapshotsByRangeAsync),
        const SizedBox(height: 32),
        _buildSectionTitle(
          context,
          'Latest Transactions',
          icon: LucideIcons.history,
        ),
        const SizedBox(height: 16),
        _buildRecentTransactions(transactionsAsync),
      ],
    );
  }

  Widget _buildRightColumn(
    BuildContext context,
    AsyncValue<List<Session>> monthlySessionsAsync,
    AsyncValue<dynamic> scheduleAsync,
    AsyncValue<dynamic> leavesAsync,
  ) {
    return Column(
      children: [
        _buildSectionTitle(
          context,
          'Session Distribution Breakdown',
          icon: LucideIcons.pieChart,
        ),
        const SizedBox(height: 16),
        _buildSessionStatusChart(context, monthlySessionsAsync),
        const SizedBox(height: 32),
        _buildSectionTitle(
          context,
          'Operational Activity Pulse',
          icon: LucideIcons.activity,
        ),
        const SizedBox(height: 16),
        _buildOperationsCard(scheduleAsync, leavesAsync, monthlySessionsAsync),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Center Overview',
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        Text(
          'Strategic and financial metrics at a glance',
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
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;
        int maxItems = 4;

        return MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,

          itemCount: maxItems,
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
    WidgetRef ref,
    AsyncValue<List<InvoiceSnapshot>> snapshotsByRangeAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        height: 300,
        padding: const EdgeInsets.fromLTRB(0, 32, 8, 16),
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
              final monthKey = s.monthKey;
              if (monthlyRevenue.containsKey(monthKey)) {
                monthlyRevenue[monthKey] =
                    monthlyRevenue[monthKey]! + s.totalAmount;
              }
            }

            final sortedMonths = monthlyRevenue.keys.toList()..sort();
            final List<BarChartGroupData> barGroups = [];

            double maxVal = 0;
            for (int i = 0; i < sortedMonths.length; i++) {
              final month = sortedMonths[i];
              final revenue = monthlyRevenue[month]!;
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

            // Calculate interval to prevent overlapping (e.g., 5 intervals)
            double interval = (maxVal / 6);
            if (interval < 1000) interval = 1000;
            // Round interval to nice number
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
                          final monthKey = sortedMonths[value.toInt()];
                          final monthDate = DateTime.parse('$monthKey-01');
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
                      reservedSize: 50,
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
                            textAlign: TextAlign.right,
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
          error: (error, stack) {
            debugPrint('Error loading revenue data: $error');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data Error: ${error.toString().split(':').first}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionStatusChart(
    BuildContext context,
    AsyncValue<List<Session>> monthlySessionsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: monthlySessionsAsync.when(
          data: (sessions) {
            int completed = 0;
            int cancelled = 0;
            int scheduled = 0;
            int pending = 0;

            for (var se in sessions) {
              if (se.status == SessionStatus.completed)
                completed++;
              else if (se.status == SessionStatus.cancelledClient ||
                  se.status == SessionStatus.cancelledCenter)
                cancelled++;
              else if (se.status == SessionStatus.scheduled)
                scheduled++;
              else if (se.status == SessionStatus.pending)
                pending++;
            }

            final total = (completed + cancelled + scheduled + pending)
                .toDouble();
            if (total == 0)
              return const Center(
                child: Text('No session data for this month.'),
              );

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          _buildPieSection(completed, total, Colors.green),
                          _buildPieSection(cancelled, total, Colors.red),
                          _buildPieSection(scheduled, total, Colors.blueAccent),
                          _buildPieSection(pending, total, Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Completed', completed, Colors.green),
                      const SizedBox(height: 8),
                      _buildLegendItem('Cancelled', cancelled, Colors.red),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Scheduled',
                        scheduled,
                        Colors.blueAccent,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem('Pending', pending, Colors.amber),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint('Error loading session data: $error');
            return const Center(child: Text('Error loading session data'));
          },
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(int value, double total, Color color) {
    final percentage = (value / total) * 100;
    return PieChartSectionData(
      value: value.toDouble(),
      title: '${percentage.toStringAsFixed(0)}%',
      color: color,
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($value)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    AsyncValue<List<ClientTransaction>> transactionsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: Text('No recent transactions.')),
            );
          }
          final displayList = transactions.take(6).toList();
          return Column(
            children: [
              ...displayList.map((tx) {
                final isCredit = tx.type == TransactionType.prepaid;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: ListTile(
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
                      tx.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('MMM dd, hh:mm a').format(tx.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Text(
                      '${isCredit ? "+" : "-"} ৳${NumberFormat('#,###').format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: isCredit ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const Center(child: Text('Error loading activity')),
      ),
    );
  }

  Widget _buildOperationsCard(
    AsyncValue<dynamic> scheduleAsync,
    AsyncValue<dynamic> leavesAsync,
    AsyncValue<List<Session>> monthlySessionsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildOpItem(
              'Today\'s Sessions',
              scheduleAsync.when(
                data: (view) => view.sessionsByTimeSlot.values
                    .fold(0, (sum, list) => sum + list.length)
                    .toString(),
                loading: () => '...',
                error: (_, _) => '0',
              ),
              LucideIcons.calendar,
              Colors.blue,
            ),
            const Divider(height: 32),
            _buildOpItem(
              'Pending Leaves',
              leavesAsync.when(
                data: (leaves) => (leaves as List)
                    .where((l) => l.status == LeaveStatus.pending)
                    .length
                    .toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              LucideIcons.fileText,
              Colors.orange,
            ),
            const Divider(height: 32),
            _buildOpItem(
              'Monthly Capacity',
              monthlySessionsAsync.when(
                data: (sessions) => sessions.length.toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              LucideIcons.layers,
              Colors.indigo,
            ),
            const Divider(height: 32),
            _buildOpItem(
              'Cancellations',
              monthlySessionsAsync.when(
                data: (sessions) => sessions
                    .where(
                      (se) =>
                          se.status == SessionStatus.cancelledClient ||
                          se.status == SessionStatus.cancelledCenter,
                    )
                    .length
                    .toString(),
                loading: () => '...',
                error: (_, __) => '0',
              ),
              LucideIcons.xCircle,
              Colors.red,
            ),
          ],
        ),
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
                fontSize: 24, // Refined font size
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

  Widget _buildOpItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.7)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ],
    );
  }
}
