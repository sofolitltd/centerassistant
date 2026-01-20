import 'dart:convert';
import 'dart:io' as io;
import 'dart:js_interop';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

import '../../app/admin/features/schedule/presentation/pages/add/add_schedule_utils.dart';
import '../models/client.dart';
import '../models/client_discount.dart';
import '../models/service_rate.dart';
import '../models/session.dart';

class BillingExportHelper {
  static final _currencyFormat = NumberFormat('#,###');
  static final _dateFormat = DateFormat('d-MMM-yy');

  /// Find applicable global rate for a service on a specific date
  static ServiceRate? _getApplicableRate(
    List<ServiceRate> rates,
    String serviceType,
    DateTime date,
  ) {
    final validRates = rates
        .where(
          (r) => r.serviceType == serviceType && !r.effectiveDate.isAfter(date),
        )
        .toList();
    if (validRates.isEmpty) return null;
    validRates.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return validRates.first;
  }

  /// Find applicable client discount for a service on a specific date
  static ClientDiscount? _getApplicableDiscount(
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

  /// Exports session data to CSV matching the design requirements
  static Future<void> exportToCsv({
    required Client client,
    required List<Session> sessions,
    required List<ServiceRate> allRates,
    required List<ClientDiscount> allDiscounts,
    required DateTime monthDate,
  }) async {
    final List<List<dynamic>> rows = [];

    // Header based on Breakdown Page
    rows.add([
      'Date',
      'Start Time',
      'End Time',
      'Service Package',
      'Status',
      'Total Hours',
      'Per Unit Charge',
      'Discount (Per Hour)',
      'Amount',
    ]);

    double grandTotalAmount = 0;

    for (final s in sessions) {
      double sessionAmount = 0;
      double avgRate = 0;
      double avgDiscount = 0;

      final date = s.date.toDate();

      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        for (var sv in s.services) {
          final rate =
              _getApplicableRate(allRates, sv.type, date)?.hourlyRate ?? 0.0;
          final discount =
              _getApplicableDiscount(
                allDiscounts,
                sv.type,
                date,
              )?.discountPerHour ??
              0.0;
          sessionAmount += sv.duration * (rate - discount);
          avgRate = rate; // Simplified: showing last service rate if multiple
          avgDiscount = discount;
        }
      }
      grandTotalAmount += sessionAmount;

      final servicePackage = s.services.map((sv) => sv.type).toSet().join(', ');
      final startTime = s.services.isNotEmpty
          ? AddScheduleUtils.formatTimeToAmPm(s.services.first.startTime)
          : '';
      final endTime = s.services.isNotEmpty
          ? AddScheduleUtils.formatTimeToAmPm(s.services.last.endTime)
          : '';

      rows.add([
        _dateFormat.format(date),
        startTime,
        endTime,
        servicePackage,
        s.status.displayName,
        s.totalDuration.toStringAsFixed(1),
        avgRate.toStringAsFixed(0),
        avgDiscount.toStringAsFixed(0),
        sessionAmount.toStringAsFixed(0),
      ]);
    }

    rows.add([]);
    rows.add([
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'Total',
      grandTotalAmount.toStringAsFixed(0),
    ]);

    String csvData = const ListToCsvConverter().convert(rows);
    final fileName =
        '${client.name.replaceAll(' ', '_')}_Breakdown_${DateFormat('MMM_yyyy').format(monthDate)}.csv';

    if (kIsWeb) {
      final bytes = utf8.encode(csvData);
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'text/csv'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      web.URL.revokeObjectURL(url);
    } else {
      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsString(csvData);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Breakdown Export for ${client.name}');
    }
  }

  /// Generates a professional PDF Invoice document
  static Future<pw.Document> _buildInvoiceDocument({
    required Client client,
    required List<Session> sessions,
    required List<ServiceRate> allRates,
    required List<ClientDiscount> allDiscounts,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final ByteData data = await rootBundle.load(
        'assets/images/tender_twig.png',
      );
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      /* ignore */
    }

    final String invoiceMonth = DateFormat('MMM-yy').format(monthDate);
    final String invoiceDate = _dateFormat.format(DateTime.now());
    final String dueDate = _dateFormat.format(
      DateTime.now().add(const Duration(days: 7)),
    );

    // PAGE 1: Summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null) pw.Image(logo, width: 120),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'A1, House 13, Road 34, Gulshan 1',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Dhaka, Bangladesh',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'Phone: 01994446512',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        'E-Mail: info@tendertwigbd.com',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Monthly Invoice',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildInvoiceDetailsGrid(
                        client,
                        invoiceDate,
                        invoiceMonth,
                        dueDate,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              _buildSummaryTable(sessions, allRates, allDiscounts),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  _buildTotalsTable(totalMonthlyBill, client.walletBalance),
                ],
              ),
              pw.SizedBox(height: 30),
              _buildPaymentTerms(),
            ],
          );
        },
      ),
    );

    // PAGE 2: Breakdown
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Breakdown of Services',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              _buildBreakdownTable(
                sessions,
                allRates,
                allDiscounts,
                totalMonthlyBill,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInvoiceDetailsGrid(
    Client client,
    String date,
    String month,
    String due,
  ) {
    const s = pw.TextStyle(fontSize: 10);
    var b = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(100),
        1: const pw.FixedColumnWidth(100),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        _buildGridRow('Bill To', client.clientId, s, b),
        _buildGridRow('Invoice Date', date, s, b),
        _buildGridRow('Invoice Month', month, s, b),
        _buildGridRow('Payment Due Date', due, s, b),
      ],
    );
  }

  static pw.TableRow _buildGridRow(
    String l,
    String v,
    pw.TextStyle s,
    pw.TextStyle b,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(l, style: s, textAlign: pw.TextAlign.right),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(v, style: b, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryTable(
    List<Session> sessions,
    List<ServiceRate> allRates,
    List<ClientDiscount> allDiscounts,
  ) {
    // Group by Service Type
    final Map<String, _SummaryData> summary = {};
    for (var s in sessions) {
      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        final date = s.date.toDate();
        for (var sv in s.services) {
          final rate =
              _getApplicableRate(allRates, sv.type, date)?.hourlyRate ?? 0.0;
          final discount =
              _getApplicableDiscount(
                allDiscounts,
                sv.type,
                date,
              )?.discountPerHour ??
              0.0;

          summary.update(
            sv.type,
            (val) => val
              ..hours += sv.duration
              ..total += (sv.duration * (rate - discount)),
            ifAbsent: () => _SummaryData(
              sv.type,
              sv.duration,
              rate,
              discount,
              sv.duration * (rate - discount),
            ),
          );
        }
      }
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(60),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(80),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildCell('Description', isHeader: true),
            _buildCell('Hours', isHeader: true),
            _buildCell('Per Unit Charge', isHeader: true),
            _buildCell('Discount (Per Hour)', isHeader: true),
            _buildCell('Total', isHeader: true),
          ],
        ),
        ...summary.values.map(
          (d) => pw.TableRow(
            children: [
              _buildCell('${d.type} Session'),
              _buildCell(
                d.hours.toStringAsFixed(1),
                align: pw.TextAlign.center,
              ),
              _buildCell(
                _currencyFormat.format(d.rate),
                align: pw.TextAlign.center,
              ),
              _buildCell(
                _currencyFormat.format(d.discount),
                align: pw.TextAlign.center,
              ),
              _buildCell(
                _currencyFormat.format(d.total),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalsTable(double totalBill, double advance) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(160),
        1: const pw.FixedColumnWidth(80),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      children: [
        _buildSimpleRow('Total', _currencyFormat.format(totalBill)),
        _buildSimpleRow(
          'Advance/(Previous Due)',
          _currencyFormat.format(advance),
        ),
        _buildSimpleRow(
          'Net Payable/ (Remaining Balance)',
          _currencyFormat.format(advance - totalBill),
          isBold: true,
        ),
      ],
    );
  }

  static pw.TableRow _buildSimpleRow(
    String l,
    String v, {
    bool isBold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 10,
      fontWeight: isBold ? pw.FontWeight.bold : null,
    );
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(l, style: style, textAlign: pw.TextAlign.right),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(v, style: style, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static pw.Widget _buildBreakdownTable(
    List<Session> sessions,
    List<ServiceRate> allRates,
    List<ClientDiscount> allDiscounts,
    double grandTotal,
  ) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(60),
        1: const pw.FixedColumnWidth(55),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(40),
        6: const pw.FixedColumnWidth(60),
        7: const pw.FixedColumnWidth(60),
        8: const pw.FixedColumnWidth(60),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildCell('Date', isHeader: true),
            _buildCell('Start Time', isHeader: true),
            _buildCell('End Time', isHeader: true),
            _buildCell('Service Package', isHeader: true),
            _buildCell('Status', isHeader: true),
            _buildCell('Total Hours', isHeader: true),
            _buildCell('Per Unit Charge', isHeader: true),
            _buildCell('Discount (Per Hour)', isHeader: true),
            _buildCell('Amount', isHeader: true),
          ],
        ),
        ...sessions.map((s) {
          double sessionAmount = 0;
          double rate = 0;
          double discount = 0;
          final date = s.date.toDate();
          if (s.status == SessionStatus.completed ||
              s.status == SessionStatus.scheduled) {
            for (var sv in s.services) {
              rate =
                  _getApplicableRate(allRates, sv.type, date)?.hourlyRate ??
                  0.0;
              discount =
                  _getApplicableDiscount(
                    allDiscounts,
                    sv.type,
                    date,
                  )?.discountPerHour ??
                  0.0;
              sessionAmount += sv.duration * (rate - discount);
            }
          }
          return pw.TableRow(
            children: [
              _buildCell(_dateFormat.format(date)),
              _buildCell(
                s.services.isNotEmpty
                    ? AddScheduleUtils.formatTimeToAmPm(
                        s.services.first.startTime,
                      )
                    : '',
              ),
              _buildCell(
                s.services.isNotEmpty
                    ? AddScheduleUtils.formatTimeToAmPm(s.services.last.endTime)
                    : '',
              ),
              _buildCell(s.services.map((sv) => sv.type).toSet().join(', ')),
              _buildCell(s.status.displayName),
              _buildCell(
                s.totalDuration.toStringAsFixed(1),
                align: pw.TextAlign.center,
              ),
              _buildCell(
                _currencyFormat.format(rate),
                align: pw.TextAlign.center,
              ),
              _buildCell(
                _currencyFormat.format(discount),
                align: pw.TextAlign.center,
              ),
              _buildCell(
                _currencyFormat.format(sessionAmount),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            _buildCell('Total', isBold: true, align: pw.TextAlign.right),
            _buildCell(
              _currencyFormat.format(grandTotal),
              isBold: true,
              align: pw.TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 9,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : null,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildPaymentTerms() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mode of Payment',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(
            'CASH/CARD/CHEQUE/ONLINE TRANSFER (In case of Card payment 1.5% charge is applicable).',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Bank details:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(
            'Account Name: M/S. TENDER TWIG, Account No:2077080460001, Bank Name: BRAC Bank Ltd., Bank Branch: Banani Branch, Routing No: 060260435.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Disclaimer',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Text(
            'Failure to clear the fees by the due date will result in the temporary suspension of all services until all outstanding fees are cleared.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static Future<void> generateInvoicePdf({
    required Client client,
    required List<Session> sessions,
    required List<ServiceRate> allRates,
    required List<ClientDiscount> allDiscounts,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = await _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      allRates: allRates,
      allDiscounts: allDiscounts,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
    );
    final fileName =
        '${client.name.replaceAll(' ', '_')}_Invoice_${DateFormat('MMM_yyyy').format(monthDate)}.pdf';
    if (kIsWeb) {
      final bytes = await pdf.save();
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/pdf'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      web.URL.revokeObjectURL(url);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
    }
  }

  static Future<void> printInvoice({
    required Client client,
    required List<Session> sessions,
    required List<ServiceRate> allRates,
    required List<ClientDiscount> allDiscounts,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = await _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      allRates: allRates,
      allDiscounts: allDiscounts,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> shareInvoice({
    required Client client,
    required List<Session> sessions,
    required List<ServiceRate> allRates,
    required List<ClientDiscount> allDiscounts,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = await _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      allRates: allRates,
      allDiscounts: allDiscounts,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
    );
    final bytes = await pdf.save();
    final fileName = '${client.name.replaceAll(' ', '_')}_Invoice.pdf';
    if (kIsWeb) {
      await generateInvoicePdf(
        client: client,
        sessions: sessions,
        allRates: allRates,
        allDiscounts: allDiscounts,
        monthDate: monthDate,
        totalMonthlyBill: totalMonthlyBill,
      );
    } else {
      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Invoice for ${client.name}');
    }
  }
}

class _SummaryData {
  final String type;
  double hours;
  double rate;
  double discount;
  double total;
  _SummaryData(this.type, this.hours, this.rate, this.discount, this.total);
}
