import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/app/admin/features/schedule/presentation/pages/add/add_schedule_utils.dart';
import '/core/models/client_discount.dart';
import '/core/models/invoice_snapshot.dart';
import '/core/models/service_rate.dart';
import '/core/models/session.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_discount_providers.dart';
import '/core/providers/client_providers.dart';
import '/core/providers/invoice_snapshot_providers.dart';
import '/core/providers/service_rate_providers.dart';
import '/core/utils/billing_export_helper.dart';

class BillingSnapshotsTab extends ConsumerWidget {
  final String clientId;
  final InvoiceType type;
  final String? monthKey;

  const BillingSnapshotsTab({
    super.key,
    required this.clientId,
    required this.type,
    this.monthKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = monthKey != null
        ? ref.watch(
            invoiceSnapshotsByMonthProvider((
              clientId: clientId,
              monthKey: monthKey!,
              type: type,
            )),
          )
        : ref.watch(invoiceSnapshotsProvider((clientId: clientId, type: type)));

    final allServiceRatesAsync = ref.watch(allServiceRatesProvider);
    final allDiscountsAsync = ref.watch(clientDiscountsProvider(clientId));
    final currencyFormat = NumberFormat('#,###');

    return snapshotsAsync.when(
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == InvoiceType.pre
                      ? LucideIcons.fileSearch
                      : LucideIcons.checkCircle,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  type == InvoiceType.pre
                      ? 'No pro-forma snapshots found.'
                      : 'No finalized invoices found.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return allServiceRatesAsync.when(
          data: (allRates) => allDiscountsAsync.when(
            data: (allDiscounts) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: snapshots.length,
                itemBuilder: (context, index) {
                  final snapshot = snapshots[index];
                  final sessions = snapshot.sessionsJson
                      .map((j) => Session.fromJson(j))
                      .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              _buildSnapshotDataTable(
                                sessions,
                                allRates,
                                allDiscounts,
                                currencyFormat,
                              ),
                              _buildSnapshotSummarySection(
                                snapshot,
                                sessions,
                                currencyFormat,
                                allRates,
                                allDiscounts,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final isBilledAsync = type == InvoiceType.post
                                ? ref.watch(
                                    checkMonthBilledProvider((
                                      clientId: clientId,
                                      monthKey: snapshot.monthKey,
                                    )),
                                  )
                                : const AsyncValue.data(false);

                            return isBilledAsync.when(
                              data: (isBilled) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (type == InvoiceType.post &&
                                        !isBilled) ...[
                                      ElevatedButton.icon(
                                        onPressed: () => _handleFinalize(
                                          context,
                                          ref,
                                          snapshot,
                                        ),
                                        icon: const Icon(
                                          LucideIcons.checkCircle,
                                          size: 16,
                                        ),
                                        label: const Text('Confirm & Finalize'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],

                                    if (type == InvoiceType.pre || isBilled)
                                      _buildSnapshotExportMenu(
                                        context,
                                        snapshot,
                                        sessions,
                                        allRates,
                                        allDiscounts,
                                      ),

                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          _handleDelete(context, ref, snapshot),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      tooltip: 'Delete Snapshot',
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        if (index < snapshots.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _handleFinalize(
    BuildContext context,
    WidgetRef ref,
    InvoiceSnapshot snapshot,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Finalization'),
        content: Text(
          'Confirm deduction of ৳${NumberFormat('#,###').format(snapshot.totalAmount)} from wallet for ${snapshot.monthKey}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Deduct'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final client = await ref.read(
        clientByIdProvider(snapshot.clientId).future,
      );
      if (client != null) {
        await ref
            .read(billingServiceProvider)
            .finalizeMonthlyBill(
              client: client,
              totalBill: snapshot.totalAmount,
              monthDate: DateTime.parse('${snapshot.monthKey}-01'),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Monthly bill finalized and deducted.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    InvoiceSnapshot snapshot,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snapshot?'),
        content: const Text(
          'Are you sure you want to delete this snapshot? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(invoiceSnapshotServiceProvider).deleteSnapshot(snapshot);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Snapshot deleted.')));
      }
    }
  }

  Widget _buildSnapshotDataTable(
    List<Session> sessions,
    List<ServiceRate> allRates,
    List<ClientDiscount> allDiscounts,
    NumberFormat currencyFormat,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
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
              rows: sessions.map((s) {
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(sv.type, style: const TextStyle(fontSize: 10)),
                    ),
                  );

                  timeWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)}',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  );

                  hourWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${sv.duration}h',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );

                  rateWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '৳${currencyFormat.format(r)}',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  );

                  discountWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '৳${currencyFormat.format(d)}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  );

                  typeWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        sv.sessionType.displayName,
                        style: const TextStyle(fontSize: 9),
                      ),
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
                        DateFormat('dd-MM-yyyy').format(date),
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
                    DataCell(_buildStatusBadge(s.status)),
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
        );
      },
    );
  }

  Widget _buildSnapshotSummarySection(
    InvoiceSnapshot snapshot,
    List<Session> sessions,
    NumberFormat currencyFormat,
    List<ServiceRate> allRates,
    List<ClientDiscount> allDiscounts,
  ) {
    int completedCount = sessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    int centerCancelledCount = sessions
        .where((s) => s.status == SessionStatus.cancelledCenter)
        .length;
    int clientCancelledCount = sessions
        .where((s) => s.status == SessionStatus.cancelledClient)
        .length;

    double totalDiscount = 0;
    for (var s in sessions) {
      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        final date = s.date.toDate();
        for (var sv in s.services) {
          final d =
              BillingExportHelper.getApplicableDiscount(
                allDiscounts,
                sv.type,
                date,
              )?.discountPerHour ??
              0.0;
          totalDiscount += sv.duration * d;
        }
      }
    }
    final totalGross = snapshot.totalAmount + totalDiscount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Hours',
            '${snapshot.totalHours.toStringAsFixed(1)} h',
          ),

          //
          if (snapshot.type != InvoiceType.pre) ...[
            _buildSummaryRow('Completed', '$completedCount'),
            _buildSummaryRow('Cancelled (Client)', '$clientCancelledCount'),
            _buildSummaryRow('Cancelled (Center)', '$centerCancelledCount'),
          ],

          const Divider(),
          _buildSummaryRow(
            'Gross Amount',
            '৳ ${currencyFormat.format(totalGross)}',
          ),
          _buildSummaryRow(
            'Total Discount',
            '- ৳ ${currencyFormat.format(totalDiscount)}',
            color: Colors.red,
          ),

          const Divider(),
          _buildSummaryRow(
            'Total Monthly Bill',
            '৳ ${currencyFormat.format(snapshot.totalAmount)}',
            color: Colors.black,
            isBold: true,
          ),

          //
          const Divider(),
          _buildSummaryRow(
            'Advances/Previous Due',
            '৳ ${currencyFormat.format(snapshot.walletBalanceAtTime)}',
          ),
          _buildSummaryRow(
            'Net Payable / Remaining Balance',
            '৳ ${currencyFormat.format(snapshot.walletBalanceAtTime - snapshot.totalAmount)}',
            isBold: true,
            color: Colors.blue.shade800,
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.black87 : Colors.grey.shade700,
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
    );
  }

  Widget _buildSnapshotExportMenu(
    BuildContext context,
    InvoiceSnapshot snapshot,
    List<Session> sessions,
    List<ServiceRate> allRates,
    List<ClientDiscount> allDiscounts,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        final client = await ProviderScope.containerOf(
          context,
        ).read(clientByIdProvider(snapshot.clientId).future);
        if (client == null) return;

        final monthDate = DateTime.parse('${snapshot.monthKey}-01');

        if (value == 'csv') {
          await BillingExportHelper.exportToCsv(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: monthDate,
          );
        } else if (value == 'pdf') {
          await BillingExportHelper.generateInvoicePdf(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: monthDate,
            totalMonthlyBill: snapshot.totalAmount,
            isDraft: snapshot.type == InvoiceType.pre,
          );
        } else if (value == 'print') {
          await BillingExportHelper.printInvoice(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: monthDate,
            totalMonthlyBill: snapshot.totalAmount,
            isDraft: snapshot.type == InvoiceType.pre,
          );
        } else if (value == 'share') {
          await BillingExportHelper.shareInvoice(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: monthDate,
            totalMonthlyBill: snapshot.totalAmount,
            isDraft: snapshot.type == InvoiceType.pre,
          );
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.download, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text('Download PDF Invoice')),
        const PopupMenuItem(value: 'print', child: Text('Print PDF Invoice')),
        const PopupMenuItem(value: 'share', child: Text('Share PDF Invoice')),
        const PopupMenuItem(value: 'csv', child: Text('Export CSV Breakdown')),
      ],
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    Color color;
    String label;
    switch (status) {
      case SessionStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case SessionStatus.cancelledCenter:
        color = Colors.red;
        label = 'Cancelled (Center)';
        break;
      case SessionStatus.cancelledClient:
        color = Colors.orange;
        label = 'Cancelled (Client)';
        break;
      case SessionStatus.pending:
        color = Colors.amber;
        label = 'Pending';
        break;
      case SessionStatus.scheduled:
        color = Colors.blue;
        label = 'Scheduled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
