import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/core/models/client.dart';
import '/core/models/client_discount.dart';
import '/core/models/service_rate.dart';
import '/core/models/session.dart';
import '/core/providers/billing_providers.dart';
import '/core/providers/client_discount_providers.dart';
import '/core/providers/service_rate_providers.dart';
import '/core/utils/billing_export_helper.dart';
import 'billing_month_navigator.dart';

class BillingSessionsTab extends ConsumerWidget {
  final Client client;
  final AsyncValue<List<Session>> sessionsAsync;

  const BillingSessionsTab({
    super.key,
    required this.client,
    required this.sessionsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allServiceRatesAsync = ref.watch(allServiceRatesProvider);
    final allDiscountsAsync = ref.watch(clientDiscountsProvider(client.id));
    final currencyFormat = NumberFormat('#,###');

    return sessionsAsync.when(
      data: (sessions) {
        final sorted = List<Session>.from(sessions)
          ..sort((a, b) => b.date.compareTo(a.date));

        return allServiceRatesAsync.when(
          data: (allRates) {
            return allDiscountsAsync.when(
              data: (allDiscounts) {
                double totalMonthlyBill = 0;
                double totalHours = 0;
                int completedCount = 0;
                int clientCancelledCount = 0;
                int centerCancelledCount = 0;

                // Pre-calculate session bills to pass to export helper later if needed
                // but for now we'll just calculate here.

                final selectedMonth = ref.read(selectedBillingMonthProvider);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Sessions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const BillingMonthNavigator(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (sessions.isEmpty)
                        _buildEmptyState('No sessions found for this month.')
                      else ...[
                        Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade50,
                                  ),
                                  headingRowHeight: 40,
                                  columnSpacing: 20,
                                  border: TableBorder.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  columns: const [
                                    DataColumn(label: _HeaderCell('Date')),
                                    DataColumn(label: _HeaderCell('Service')),
                                    DataColumn(label: _HeaderCell('Hour')),
                                    DataColumn(label: _HeaderCell('Rate')),
                                    DataColumn(label: _HeaderCell('Discount')),
                                    DataColumn(label: _HeaderCell('Status')),
                                    DataColumn(
                                      label: _HeaderCell('Bill'),
                                      numeric: true,
                                    ),
                                  ],
                                  rows: sorted.map((s) {
                                    double sessionTotalBill = 0;
                                    double sessionTotalDiscount = 0;

                                    final sessionDate = s.date.toDate();

                                    List<Widget> serviceDetails = [];
                                    List<String> ratesText = [];
                                    List<String> discountsText = [];

                                    for (var service in s.services) {
                                      // Get applicable global rate
                                      final applicableRate = _getApplicableRate(
                                        allRates,
                                        service.type,
                                        sessionDate,
                                      );
                                      // Get applicable client discount
                                      final applicableDiscount =
                                          _getApplicableDiscount(
                                            allDiscounts,
                                            service.type,
                                            sessionDate,
                                          );

                                      final double rate =
                                          applicableRate?.hourlyRate ?? 0.0;
                                      final double discount =
                                          applicableDiscount?.discountPerHour ??
                                          0.0;
                                      final double netRate = rate - discount;

                                      if (s.status == SessionStatus.completed ||
                                          s.status == SessionStatus.scheduled) {
                                        sessionTotalBill +=
                                            service.duration * netRate;
                                        sessionTotalDiscount +=
                                            service.duration * discount;
                                      }

                                      serviceDetails.add(
                                        Text(
                                          '${service.type} (${service.sessionType.displayName})',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      );
                                      ratesText.add(
                                        '৳${currencyFormat.format(rate)}',
                                      );
                                      discountsText.add(
                                        '৳${currencyFormat.format(discount)}',
                                      );
                                    }

                                    if (s.status == SessionStatus.completed ||
                                        s.status == SessionStatus.scheduled) {
                                      if (s.status == SessionStatus.completed)
                                        completedCount++;
                                      totalHours += s.totalDuration;
                                      totalMonthlyBill += sessionTotalBill;
                                    } else if (s.status ==
                                        SessionStatus.cancelledCenter) {
                                      centerCancelledCount++;
                                    } else if (s.status ==
                                        SessionStatus.cancelledClient) {
                                      clientCancelledCount++;
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            DateFormat(
                                              'dd-MM-yy',
                                            ).format(sessionDate),
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: serviceDetails,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${s.totalDuration}h',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            ratesText.join('\n'),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            discountsText.join('\n'),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                        DataCell(_buildStatusBadge(s.status)),
                                        DataCell(
                                          Text(
                                            '৳${currencyFormat.format(sessionTotalBill)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Summary section
                              _buildSummarySection(
                                client,
                                totalHours,
                                completedCount,
                                clientCancelledCount,
                                centerCancelledCount,
                                totalMonthlyBill,
                                currencyFormat,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildExportButtons(
                          client,
                          sessions,
                          allRates,
                          allDiscounts,
                          selectedMonth,
                          totalMonthlyBill,
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading discounts: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading rates: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  ServiceRate? _getApplicableRate(
    List<ServiceRate> rates,
    String serviceType,
    DateTime date,
  ) {
    // Find all rates for this service type that were effective ON OR BEFORE the session date
    final validRates = rates
        .where(
          (r) => r.serviceType == serviceType && !r.effectiveDate.isAfter(date),
        )
        .toList();
    if (validRates.isEmpty) return null;
    // Pick the most recent one
    validRates.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return validRates.first;
  }

  ClientDiscount? _getApplicableDiscount(
    List<ClientDiscount> discounts,
    String serviceType,
    DateTime date,
  ) {
    final validDiscounts = discounts
        .where(
          (d) =>
              d.serviceType == serviceType &&
              d.isActive &&
              !d.effectiveDate.isAfter(date),
        )
        .toList();
    if (validDiscounts.isEmpty) return null;
    validDiscounts.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return validDiscounts.first;
  }

  Widget _buildSummarySection(
    Client client,
    double totalHours,
    int completedCount,
    int clientCancelledCount,
    int centerCancelledCount,
    double totalMonthlyBill,
    NumberFormat currencyFormat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Hours', '${totalHours.toStringAsFixed(1)} h'),
          const SizedBox(height: 4),
          _buildSummaryRow('Completed Sessions', '$completedCount'),
          const SizedBox(height: 4),
          _buildSummaryRow('Client Cancelled', '$clientCancelledCount'),
          const SizedBox(height: 4),
          _buildSummaryRow('Center Cancelled', '$centerCancelledCount'),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Current Prepaid Balance',
            '৳ ${currencyFormat.format(client.walletBalance)}',
          ),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Monthly Bill (Subtract)',
            '- ৳ ${currencyFormat.format(totalMonthlyBill)}',
            color: Colors.red.shade700,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildSummaryRow(
            'Remaining Balance',
            '৳ ${currencyFormat.format(client.walletBalance - totalMonthlyBill)}',
            isBold: true,
            color: Colors.blue.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons(
    Client client,
    List<Session> sessions,
    List<ServiceRate> allRates,
    List<ClientDiscount> allDiscounts,
    DateTime selectedMonth,
    double totalMonthlyBill,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => BillingExportHelper.exportToCsv(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: selectedMonth,
          ),
          icon: const Icon(LucideIcons.download, size: 18),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => BillingExportHelper.generateInvoicePdf(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: selectedMonth,
            totalMonthlyBill: totalMonthlyBill,
          ),
          icon: const Icon(LucideIcons.fileText, size: 18),
          label: const Text('Download Invoice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: () => BillingExportHelper.printInvoice(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: selectedMonth,
            totalMonthlyBill: totalMonthlyBill,
          ),
          icon: const Icon(LucideIcons.printer, size: 18),
          tooltip: 'Print Invoice',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => BillingExportHelper.shareInvoice(
            client: client,
            sessions: sessions,
            allRates: allRates,
            allDiscounts: allDiscounts,
            monthDate: selectedMonth,
            totalMonthlyBill: totalMonthlyBill,
          ),
          icon: const Icon(LucideIcons.share2, size: 18),
          tooltip: 'Share Invoice',
        ),
      ],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarX, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  );
}
