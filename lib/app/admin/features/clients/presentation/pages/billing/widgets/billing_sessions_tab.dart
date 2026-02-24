import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/admin/features/schedule/presentation/pages/add/add_schedule_utils.dart';
import '/app/admin/features/schedule/presentation/pages/home/widgets/status_update_dialog.dart';
import '/core/models/client.dart';
import '/core/models/client_discount.dart';
import '/core/models/invoice_snapshot.dart';
import '/core/models/service_rate.dart';
import '/core/models/session.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_discount_providers.dart';
import '/core/providers/employee_providers.dart';
import '/core/providers/invoice_snapshot_providers.dart';
import '/core/providers/service_rate_providers.dart';
import '/core/providers/session_providers.dart';
import '/core/utils/billing_export_helper.dart';
import 'billing_month_navigator.dart';
import 'billing_snapshots_tab.dart';

class BillingSessionsTab extends ConsumerStatefulWidget {
  final Client client;
  final AsyncValue<List<Session>> sessionsAsync;

  const BillingSessionsTab({
    super.key,
    required this.client,
    required this.sessionsAsync,
  });

  @override
  ConsumerState<BillingSessionsTab> createState() => _BillingSessionsTabState();
}

class _BillingSessionsTabState extends ConsumerState<BillingSessionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: ref.read(billingSessionsTabIndexProvider),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(billingSessionsTabIndexProvider.notifier).state =
            _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedBillingMonthProvider);
    final monthKey = DateFormat('yyyy-MM').format(selectedMonth);

    // Sync tab controller if the provider changes from elsewhere
    ref.listen(billingSessionsTabIndexProvider, (prev, next) {
      if (next != _tabController.index) {
        _tabController.animateTo(next);
      }
    });

    return Column(
      children: [
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _LiveSessionsView(
                client: widget.client,
                sessionsAsync: widget.sessionsAsync,
              ),
              BillingSnapshotsTab(
                clientId: widget.client.id,
                type: InvoiceType.pre,
                monthKey: monthKey,
              ),
              BillingSnapshotsTab(
                clientId: widget.client.id,
                type: InvoiceType.post,
                monthKey: monthKey,
              ),
            ],
          ),
        ),

        // Bottom Excel-style Tabs & Month Navigator
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.black54,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                      left: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: const [
                    Tab(text: 'Live'),
                    Tab(text: 'Pre Invoice'),
                    Tab(text: 'Post Invoice'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 2, left: 8),
                child: BillingMonthNavigator(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveSessionsView extends ConsumerWidget {
  final Client client;
  final AsyncValue<List<Session>> sessionsAsync;
  const _LiveSessionsView({required this.client, required this.sessionsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRates = ref.watch(allServiceRatesProvider).value ?? [];
    final allDiscounts =
        ref.watch(clientDiscountsProvider(client.id)).value ?? [];
    final selectedMonth = ref.watch(selectedBillingMonthProvider);
    final monthKey = DateFormat('yyyy-MM').format(selectedMonth);
    final currencyFormat = NumberFormat('#,###');

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('No live sessions found.'));
        }
        final sorted = List<Session>.from(sessions)
          ..sort((a, b) => b.date.compareTo(a.date));

        // Calculate Summary Data
        double totalHours = 0;
        double totalGross = 0;
        double totalDiscount = 0;
        int completedCount = 0;
        int clientCancelledCount = 0;
        int centerCancelledCount = 0;

        for (var s in sessions) {
          if (s.status == SessionStatus.completed) completedCount++;
          if (s.status == SessionStatus.cancelledClient) clientCancelledCount++;
          if (s.status == SessionStatus.cancelledCenter) centerCancelledCount++;

          if (s.status == SessionStatus.completed ||
              s.status == SessionStatus.scheduled) {
            totalHours += s.totalDuration;
            final date = s.date.toDate();
            for (var sv in s.services) {
              final r =
                  BillingExportHelper.getApplicableRate(
                    allRates,
                    sv.type,
                    date,
                  )?.hourlyRate ??
                  0.0;
              final d =
                  BillingExportHelper.getApplicableDiscount(
                    allDiscounts,
                    sv.type,
                    date,
                  )?.discountPerHour ??
                  0.0;
              totalGross += sv.duration * r;
              totalDiscount += sv.duration * d;
            }
          }
        }
        final totalNet = totalGross - totalDiscount;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //
                    _DataTableWidget(
                      client: client,
                      sorted: sorted,
                      allRates: allRates,
                      allDiscounts: allDiscounts,
                      currencyFormat: currencyFormat,
                    ),

                    Consumer(
                      builder: (context, ref, child) {
                        final isBilledAsync = ref.watch(
                          checkMonthBilledProvider((
                            clientId: client.id,
                            monthKey: monthKey,
                          )),
                        );
                        return isBilledAsync.maybeWhen(
                          data: (isBilled) => _buildSummarySection(
                            totalHours: totalHours,
                            completedCount: completedCount,
                            clientCancelledCount: clientCancelledCount,
                            centerCancelledCount: centerCancelledCount,
                            totalGross: totalGross,
                            totalDiscount: totalDiscount,
                            totalNet: totalNet,
                            walletBalance: client.walletBalance,
                            currencyFormat: currencyFormat,
                            isBilled: isBilled,
                          ),
                          orElse: () => _buildSummarySection(
                            totalHours: totalHours,
                            completedCount: completedCount,
                            clientCancelledCount: clientCancelledCount,
                            centerCancelledCount: centerCancelledCount,
                            totalGross: totalGross,
                            totalDiscount: totalDiscount,
                            totalNet: totalNet,
                            walletBalance: client.walletBalance,
                            currencyFormat: currencyFormat,
                            isBilled: false,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              //
              Consumer(
                builder: (context, ref, child) {
                  final hasPreAsync = ref.watch(
                    hasPreSnapshotProvider((
                      clientId: client.id,
                      monthKey: monthKey,
                    )),
                  );
                  final isBilledAsync = ref.watch(
                    checkMonthBilledProvider((
                      clientId: client.id,
                      monthKey: monthKey,
                    )),
                  );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      hasPreAsync.maybeWhen(
                        data: (hasPre) => !hasPre
                            ? ElevatedButton.icon(
                                onPressed: () => _handleTakeSnapshot(
                                  ref,
                                  context,
                                  totalNet,
                                  totalHours,
                                  sessions,
                                ),
                                icon: const Icon(Icons.drafts, size: 16),
                                label: const Text('Save Pre Invoice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),

                      //
                      isBilledAsync.maybeWhen(
                        data: (isBilled) => !isBilled
                            ? ElevatedButton.icon(
                                onPressed: () => _showConfirmFinalizeDialog(
                                  context,
                                  ref,
                                  totalNet,
                                  totalHours,
                                  sessions,
                                ),
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Save Post Invoice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSummarySection({
    required double totalHours,
    required int completedCount,
    required int clientCancelledCount,
    required int centerCancelledCount,
    required double totalGross,
    required double totalDiscount,
    required double totalNet,
    required double walletBalance,
    required NumberFormat currencyFormat,
    required bool isBilled,
  }) {
    final double finalBalance = walletBalance - totalNet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Hours', '${totalHours.toStringAsFixed(1)} h'),
          _buildSummaryRow('Completed', '$completedCount'),
          _buildSummaryRow('Cancelled (Client)', '$clientCancelledCount'),
          _buildSummaryRow('Cancelled (Center)', '$centerCancelledCount'),

          const Divider(height: 24),
          _buildSummaryRow(
            'Gross Amount',
            '৳ ${currencyFormat.format(totalGross)}',
          ),
          _buildSummaryRow(
            'Total Discount',
            '৳ ${currencyFormat.format(totalDiscount)}',
            color: Colors.red,
          ),

          const Divider(height: 24),
          _buildSummaryRow(
            'Total Monthly Bill',
            '৳ ${currencyFormat.format(totalNet)}',
            color: Colors.black,
            isBold: true,
          ),

          if (!isBilled) ...[
            const Divider(height: 24),

            _buildSummaryRow(
              walletBalance >= 0 ? 'Advance Paid' : 'Due Amount',
              '৳ ${currencyFormat.format(walletBalance.abs())}',
              color: walletBalance >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
            _buildSummaryRow(
              finalBalance >= 0 ? 'Remaining Balance' : 'Net Payable',
              '৳ ${currencyFormat.format(finalBalance.abs())}',
              isBold: true,
              color: finalBalance >= 0
                  ? Colors.green.shade800
                  : Colors.red.shade800,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? (isBold ? Colors.black87 : Colors.grey.shade700),
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- Snapshot & Finalize Logic ---
  Future<void> _handleTakeSnapshot(
    WidgetRef ref,
    BuildContext context,
    double total,
    double hours,
    List<Session> sessions,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Pre invoice'),
        content: const Text(
          'This will save a draft of the current monthly sessions. It does not affect the wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Pre Invoice'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final selectedMonth = ref.read(selectedBillingMonthProvider);
      final monthKey = DateFormat('yyyy-MM').format(selectedMonth);
      final sessionsJson = sessions.map((s) => s.toJson()).toList();
      await ref
          .read(invoiceSnapshotServiceProvider)
          .createSnapshot(
            clientId: client.id,
            monthKey: monthKey,
            type: InvoiceType.pre,
            totalAmount: total,
            totalHours: hours,
            walletBalance: client.walletBalance,
            sessionsJson: sessionsJson,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pre invoice draft saved.')),
        );
      }
    }
  }

  Future<void> _showConfirmFinalizeDialog(
    BuildContext context,
    WidgetRef ref,
    double total,
    double hours,
    List<Session> sessions,
  ) async {
    final selectedMonth = ref.read(selectedBillingMonthProvider);
    final sessionsJson = sessions.map((s) => s.toJson()).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Monthly Settlement?'),
        content: Text(
          'This will create a POST-invoice snapshot AND deduct ৳${NumberFormat('#,###').format(total)} from the client wallet. This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(invoiceSnapshotServiceProvider)
                  .createSnapshot(
                    clientId: client.id,
                    monthKey: DateFormat('yyyy-MM').format(selectedMonth),
                    type: InvoiceType.post,
                    totalAmount: total,
                    totalHours: hours,
                    walletBalance: client.walletBalance,
                    sessionsJson: sessionsJson,
                  );
              await ref
                  .read(billingServiceProvider)
                  .finalizeMonthlyBill(
                    client: client,
                    totalBill: total,
                    monthDate: selectedMonth,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monthly bill finalized.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Deduct'),
          ),
        ],
      ),
    );
  }
}

class _DataTableWidget extends ConsumerWidget {
  final Client client;
  final List<Session> sorted;
  final List<ServiceRate> allRates;
  final List<ClientDiscount> allDiscounts;
  final NumberFormat currencyFormat;

  const _DataTableWidget({
    required this.client,
    required this.sorted,
    required this.allRates,
    required this.allDiscounts,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEmployees = ref.watch(employeesProvider).value ?? [];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingRowHeight: 40,
            columnSpacing: 16,
            horizontalMargin: 12,
            border: TableBorder.all(color: Colors.grey.shade200, width: 1),
            columns: const [
              DataColumn(label: _HeaderCell('Date')),
              DataColumn(label: _HeaderCell('Service')),
              DataColumn(label: _HeaderCell('Time')),
              DataColumn(label: _HeaderCell('Hours')),
              DataColumn(label: _HeaderCell('Rate')),
              DataColumn(label: _HeaderCell('Discount')),
              DataColumn(label: _HeaderCell('Type')),
              DataColumn(label: _HeaderCell('Status')),
              DataColumn(label: _HeaderCell('Bill'), numeric: true),
            ],
            rows: sorted.map((s) {
              double totalBill = 0;
              final date = s.date.toDate();

              List<Widget> serviceWidgets = [];
              List<Widget> timeWidgets = [];
              List<Widget> hourWidgets = [];
              List<Widget> rateWidgets = [];
              List<Widget> discountWidgets = [];
              List<Widget> typeWidgets = [];

              for (int i = 0; i < s.services.length; i++) {
                final sv = s.services[i];
                final r =
                    BillingExportHelper.getApplicableRate(
                      allRates,
                      sv.type,
                      date,
                    )?.hourlyRate ??
                    0.0;
                final d =
                    BillingExportHelper.getApplicableDiscount(
                      allDiscounts,
                      sv.type,
                      date,
                    )?.discountPerHour ??
                    0.0;

                if (s.status == SessionStatus.completed ||
                    s.status == SessionStatus.scheduled) {
                  totalBill += sv.duration * (r - d);
                }

                serviceWidgets.add(
                  Text(sv.type, style: const TextStyle(fontSize: 10)),
                );

                timeWidgets.add(
                  Text(
                    '${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );

                hourWidgets.add(
                  Text('${sv.duration}h', style: const TextStyle(fontSize: 10)),
                );

                rateWidgets.add(
                  Text(
                    '৳${currencyFormat.format(r)}',
                    style: const TextStyle(fontSize: 9),
                  ),
                );

                discountWidgets.add(
                  Text(
                    '৳${currencyFormat.format(d)}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.redAccent,
                    ),
                  ),
                );

                typeWidgets.add(
                  Text(
                    sv.sessionType.displayName,
                    style: const TextStyle(fontSize: 9),
                  ),
                );

                if (i < s.services.length - 1) {
                  const divider = Divider(height: 1, thickness: 0.5);
                  serviceWidgets.add(divider);
                  timeWidgets.add(divider);
                  hourWidgets.add(divider);
                  rateWidgets.add(divider);
                  discountWidgets.add(divider);
                  typeWidgets.add(divider);
                }
              }

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      DateFormat('dd MMM, yyyy').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: serviceWidgets,
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: timeWidgets,
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: hourWidgets,
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rateWidgets,
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: discountWidgets,
                    ),
                  ),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: typeWidgets,
                    ),
                  ),
                  DataCell(
                    _StatusBadge(
                      s.status,
                      onTap: () {
                        ref.read(selectedDateProvider.notifier).setDate(date);
                        final employeeMap = {
                          for (var e in allEmployees)
                            e.id: e.nickName.isNotEmpty ? e.nickName : e.name,
                        };
                        final card = SessionCardData(
                          sessionId: s.id,
                          clientDocId: client.id,
                          clientId: client.clientId,
                          clientName: client.name,
                          clientNickName: client.nickName,
                          status: s.status,
                          services: s.services,
                          notes: s.notes,
                          isAutoGenerated: s.isAutoGenerated,
                          employeeNames: employeeMap,
                        );

                        showDialog(
                          context: context,
                          builder: (context) => StatusUpdateDialog(
                            session: card,
                            timeSlotId: s.timeSlotId,
                          ),
                        );
                      },
                    ),
                  ),
                  DataCell(
                    Text(
                      '৳${currencyFormat.format(totalBill)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SessionStatus status;
  final VoidCallback? onTap;

  const _StatusBadge(this.status, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = {
      SessionStatus.completed: Colors.green,
      SessionStatus.scheduled: Colors.blue,
      SessionStatus.cancelledCenter: Colors.red,
      SessionStatus.cancelledClient: Colors.orange,
      SessionStatus.pending: Colors.amber,
    };
    final color = colors[status] ?? Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.displayName,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
  );
}
