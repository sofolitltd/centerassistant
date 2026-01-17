import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '/app/admin/features/schedule/presentation/pages/add/add_schedule_utils.dart';
import '/core/models/client.dart';
import '/core/models/session.dart';
import '/core/providers/billing_providers.dart';
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
    final serviceRatesAsync = ref.watch(activeServiceRatesProvider);
    final currencyFormat = NumberFormat('#,###');

    return sessionsAsync.when(
      data: (sessions) {
        final sorted = List<Session>.from(sessions)
          ..sort((a, b) => b.date.compareTo(a.date));

        return serviceRatesAsync.when(
          data: (rates) {
            final rateMap = {for (var r in rates) r.serviceType: r.hourlyRate};

            double totalMonthlyBill = 0;
            double totalHours = 0;
            int completedCount = 0;
            int clientCancelledCount = 0;
            int centerCancelledCount = 0;

            for (var s in sessions) {
              if (s.sessionType == SessionType.completed ||
                  s.sessionType == SessionType.regular ||
                  s.sessionType == SessionType.makeup ||
                  s.sessionType == SessionType.extra ||
                  s.sessionType == SessionType.cover) {
                completedCount++;
                totalHours += s.totalDuration;
                for (var service in s.services) {
                  final rate = rateMap[service.type] ?? 0.0;
                  totalMonthlyBill += service.duration * rate;
                }
              } else if (s.sessionType == SessionType.cancelledCenter) {
                centerCancelledCount++;
              } else if (s.sessionType == SessionType.cancelledClient) {
                clientCancelledCount++;
              }
            }

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
                          SizedBox(
                            width: double.maxFinite,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade50,
                              ),
                              headingRowHeight: 40,
                              // dataRowMaxHeight: 60,
                              // dataRowMinHeight: 24,
                              columnSpacing: 24,
                              border: TableBorder.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Service',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Hour',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Rate',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.end,
                                  label: Text(
                                    'Bill',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: sorted.map((s) {
                                double sessionBill = 0;
                                String ratesDisplay = '';

                                if (s.sessionType !=
                                        SessionType.cancelledCenter &&
                                    s.sessionType !=
                                        SessionType.cancelledClient) {
                                  for (var service in s.services) {
                                    final rate = rateMap[service.type] ?? 0.0;
                                    sessionBill += service.duration * rate;
                                  }
                                  ratesDisplay = s.services
                                      .map(
                                        (sv) =>
                                            '${sv.type}: ৳${currencyFormat.format(rateMap[sv.type] ?? 0)}',
                                      )
                                      .toSet()
                                      .join(', ');
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(s.date.toDate()),
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: s.services.map((sv) {
                                          return Text(
                                            ' ${sv.type} | ${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    DataCell(Text('${s.totalDuration}h')),
                                    DataCell(
                                      Text(
                                        ratesDisplay,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    DataCell(_buildStatusBadge(s.sessionType)),
                                    DataCell(
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '৳${currencyFormat.format(sessionBill)}',
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          // Summary section attached to the table
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow(
                                  'Total Hours',
                                  '${totalHours.toStringAsFixed(1)} h',
                                ),
                                const SizedBox(height: 4),
                                _buildSummaryRow(
                                  'Completed Sessions',
                                  '$completedCount',
                                ),
                                const SizedBox(height: 4),
                                _buildSummaryRow(
                                  'Client Cancelled',
                                  '$clientCancelledCount',
                                ),
                                const SizedBox(height: 4),
                                _buildSummaryRow(
                                  'Center Cancelled',
                                  '$centerCancelledCount',
                                ),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => BillingExportHelper.exportToCsv(
                            client: client,
                            sessions: sessions,
                            rateMap: rateMap,
                            monthDate: selectedMonth,
                          ),
                          icon: const Icon(LucideIcons.download, size: 18),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              BillingExportHelper.generateInvoicePdf(
                                client: client,
                                sessions: sessions,
                                rateMap: rateMap,
                                monthDate: selectedMonth,
                                totalMonthlyBill: totalMonthlyBill,
                              ),
                          icon: const Icon(LucideIcons.fileText, size: 18),
                          label: const Text('Download Invoice'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () => BillingExportHelper.printInvoice(
                            client: client,
                            sessions: sessions,
                            rateMap: rateMap,
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
                            rateMap: rateMap,
                            monthDate: selectedMonth,
                            totalMonthlyBill: totalMonthlyBill,
                          ),
                          icon: const Icon(LucideIcons.share2, size: 18),
                          tooltip: 'Share Invoice',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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

  Widget _buildStatusBadge(SessionType type) {
    Color color;
    String label;

    switch (type) {
      case SessionType.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case SessionType.cancelledCenter:
        color = Colors.red;
        label = 'Cancelled (Center)';
        break;
      case SessionType.cancelledClient:
        color = Colors.orange;
        label = 'Cancelled (Client)';
        break;
      case SessionType.makeup:
        color = Colors.blue;
        label = 'Makeup';
        break;
      case SessionType.extra:
        color = Colors.purple;
        label = 'Extra';
        break;
      case SessionType.cover:
        color = Colors.teal;
        label = 'Cover';
        break;
      default:
        color = Colors.grey;
        label = 'Scheduled';
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
