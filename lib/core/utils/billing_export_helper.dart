import 'dart:convert';
import 'dart:io' as io;
import 'dart:js_interop';

import 'package:center_assistant/core/constants/app_constants.dart';
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
  static final _displayDateFormat = DateFormat('dd MMM, yyyy');

  /// Find applicable global rate for a service on a specific date
  static ServiceRate? getApplicableRate(
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
  static ClientDiscount? getApplicableDiscount(
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

  /// Exports session data to CSV matching the Breakdown design
  static Future<void> exportToCsv({
    required Client client,
    required List<Session> sessions,
    required List<ServiceRate> allRates,
    required List<ClientDiscount> allDiscounts,
    required DateTime monthDate,
  }) async {
    final List<List<dynamic>> rows = [];

    // Header based on updated columns
    rows.add([
      'Date',
      'Service',
      'Time',
      'Hours',
      'Rate',
      'Discount',
      'Type',
      'Status',
      'Bill',
    ]);

    double grandTotalAmount = 0;

    for (final s in sessions) {
      final date = s.date.toDate();
      bool firstRowOfSession = true;

      for (var sv in s.services) {
        final rate =
            getApplicableRate(allRates, sv.type, date)?.hourlyRate ?? 0.0;
        final discount =
            getApplicableDiscount(
              allDiscounts,
              sv.type,
              date,
            )?.discountPerHour ??
            0.0;

        double serviceBill = 0;
        if (s.status == SessionStatus.completed ||
            s.status == SessionStatus.scheduled) {
          serviceBill = sv.duration * (rate - discount);
        }
        grandTotalAmount += serviceBill;

        rows.add([
          firstRowOfSession ? _displayDateFormat.format(date) : '',
          sv.type,
          '${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)}',
          sv.duration.toStringAsFixed(1),
          rate.toStringAsFixed(0),
          discount.toStringAsFixed(0),
          sv.sessionType.displayName,
          s.status.displayName,
          serviceBill.toStringAsFixed(0),
        ]);
        firstRowOfSession = false;
      }
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
        'Invoice_${client.clientId}_${DateFormat('MMM_yyyy').format(monthDate)}.csv';

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
      ], text: 'Invoice Export for Client #${client.clientId}');
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
    required double openingBalance,
    bool isDraft = true,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final ByteData data = await rootBundle.load(AppConstants.appLogo);
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      /* ignore */
    }

    final String monthKey = DateFormat('yyyy-MM').format(monthDate);
    final String reference =
        '${isDraft ? "PRE" : "FIN"}-$monthKey-${client.clientId}';
    final String invoiceMonth = DateFormat('MMM yy').format(monthDate);
    final String invoiceDate = _displayDateFormat.format(DateTime.now());
    final String dueDate = _displayDateFormat.format(
      DateTime.now().add(const Duration(days: 7)),
    );

    // Page 1: Summary and Payment Details
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (isDraft)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(4),
                  color: PdfColors.orange50,
                  child: pw.Center(
                    child: pw.Text(
                      'PRE INVOICE (DRAFT)',
                      style: pw.TextStyle(
                        color: PdfColors.orange900,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null)
                        pw.Image(logo, width: 120)
                      else
                        pw.SizedBox(height: 60),
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
                        isDraft ? 'Pre Invoice' : 'Monthly Invoice',
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
                        reference,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              _buildSummaryTable(sessions, allRates, allDiscounts),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [_buildTotalsTable(totalMonthlyBill, openingBalance)],
              ),
              pw.SizedBox(height: 30),
              _buildPaymentTerms(),
            ],
          );
        },
      ),
    );

    // Page 2+: Breakdown of Services
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            'Invoice Breakdown - Client #${client.clientId} - Reference: $reference - Page ${context.pageNumber}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Breakdown of Services',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),
          _buildBreakdownTable(
            sessions,
            allRates,
            allDiscounts,
            totalMonthlyBill,
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildInvoiceDetailsGrid(
    Client client,
    String date,
    String month,
    String due,
    String reference,
  ) {
    const s = pw.TextStyle(fontSize: 10);
    var b = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(100),
        1: const pw.FixedColumnWidth(120),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        _buildGridRow('Invoice ID', reference, s, b),
        _buildGridRow('Bill To (Client ID)', client.clientId, s, b),
        _buildGridRow('Invoice Month', month, s, b),
        _buildGridRow('Invoice Date', date, s, b),
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
    final Map<String, _SummaryData> summary = {};
    for (var s in sessions) {
      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        final date = s.date.toDate();
        for (var sv in s.services) {
          final rate =
              getApplicableRate(allRates, sv.type, date)?.hourlyRate ?? 0.0;
          final discount =
              getApplicableDiscount(
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

  static pw.Widget _buildTotalsTable(double totalBill, double openingBalance) {
    final double netResult = openingBalance - totalBill;

    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(160),
        1: const pw.FixedColumnWidth(80),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      children: [
        // 1. The Current Charges
        _buildSimpleRow(
          'Current Month Charges',
          _currencyFormat.format(totalBill),
        ),

        // 2. The Opening State (Pre-Invoice Connection)
        _buildSimpleRow(
          openingBalance >= 0
              ? 'Advance Paid (Opening)'
              : 'Due Amount (Opening)',
          _currencyFormat.format(openingBalance.abs()),
          color: openingBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
        ),

        // 3. The Final Result (Post-Invoice)
        _buildSimpleRow(
          netResult >= 0 ? 'Remaining Balance' : 'Net Payable Amount',
          _currencyFormat.format(netResult.abs()),
          isBold: true,
          color: netResult >= 0 ? PdfColors.green800 : PdfColors.red800,
        ),
      ],
    );
  }

  static pw.TableRow _buildSimpleRow(
    String l,
    String v, {
    bool isBold = false,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      fontSize: 10,
      fontWeight: isBold ? pw.FontWeight.bold : null,
      color: color ?? PdfColors.black,
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
    final List<pw.TableRow> rows = [];
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          _buildCell('Date', isHeader: true),
          _buildCell('Service', isHeader: true),
          _buildCell('Time', isHeader: true),
          _buildCell('Hours', isHeader: true),
          _buildCell('Rate', isHeader: true),
          _buildCell('Discount', isHeader: true),
          _buildCell('Type', isHeader: true),
          _buildCell('Status', isHeader: true),
          _buildCell('Bill', isHeader: true),
        ],
      ),
    );

    for (var s in sessions) {
      final date = s.date.toDate();
      bool firstRow = true;
      for (var sv in s.services) {
        final r = getApplicableRate(allRates, sv.type, date)?.hourlyRate ?? 0.0;
        final d =
            getApplicableDiscount(
              allDiscounts,
              sv.type,
              date,
            )?.discountPerHour ??
            0.0;
        double amt = 0;
        if (s.status == SessionStatus.completed ||
            s.status == SessionStatus.scheduled)
          amt = sv.duration * (r - d);

        rows.add(
          pw.TableRow(
            children: [
              _buildCell(firstRow ? _displayDateFormat.format(date) : ''),
              _buildCell(sv.type),
              _buildCell(
                '${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)}',
              ),
              _buildCell(
                sv.duration.toStringAsFixed(1),
                align: pw.TextAlign.center,
              ),
              _buildCell(_currencyFormat.format(r), align: pw.TextAlign.center),
              _buildCell(_currencyFormat.format(d), align: pw.TextAlign.center),
              _buildCell(sv.sessionType.displayName),
              _buildCell(s.status.displayName),
              _buildCell(
                _currencyFormat.format(amt),
                align: pw.TextAlign.right,
              ),
            ],
          ),
        );
        firstRow = false;
      }
    }

    rows.add(
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
    );

    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(55),
        1: const pw.FixedColumnWidth(40),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(35),
        4: const pw.FixedColumnWidth(45),
        5: const pw.FixedColumnWidth(45),
        6: const pw.FixedColumnWidth(45),
        7: const pw.FixedColumnWidth(60),
        8: const pw.FixedColumnWidth(50),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: rows,
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 7 : 8,
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
            'Account Name: M/S. TENDER TWIG,\nAccount No:2077080460001,\nBank Name: BRAC Bank Ltd.,\nBank Branch: Banani Branch,\nRouting No: 060260435.',
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
    required double openingBalance,
    bool isDraft = true,
  }) async {
    final pdf = await _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      allRates: allRates,
      allDiscounts: allDiscounts,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
      openingBalance: openingBalance,
      isDraft: isDraft,
    );

    final fileName =
        'Invoice_${client.clientId}_${DateFormat('MMM_yyyy').format(monthDate)}.pdf';
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
    required double openingBalance,
    bool isDraft = true,
  }) async {
    final pdf = await _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      allRates: allRates,
      allDiscounts: allDiscounts,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
      openingBalance: openingBalance,
      isDraft: isDraft,
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
    required double openingBalance,
    bool isDraft = true,
  }) async {
    final pdf = await _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      allRates: allRates,
      allDiscounts: allDiscounts,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
      openingBalance: openingBalance,
      isDraft: isDraft,
    );
    final bytes = await pdf.save();
    final fileName =
        'Invoice_${client.clientId}_${DateFormat('MMM_yyyy').format(monthDate)}.pdf';
    if (kIsWeb) {
      await generateInvoicePdf(
        client: client,
        sessions: sessions,
        allRates: allRates,
        allDiscounts: allDiscounts,
        monthDate: monthDate,
        totalMonthlyBill: totalMonthlyBill,
        openingBalance: openingBalance,
        isDraft: isDraft,
      );
    } else {
      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Invoice for Client #${client.clientId}');
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
