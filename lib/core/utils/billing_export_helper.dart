import 'dart:convert';
import 'dart:io' as io;
import 'dart:js_interop';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

import '../../app/admin/features/schedule/presentation/pages/add/add_schedule_utils.dart';
import '../models/client.dart';
import '../models/session.dart';

class BillingExportHelper {
  static final _currencyFormat = NumberFormat('#,###');
  static final _dateFormat = DateFormat('dd-MM-yyyy');

  /// Exports session data to CSV and triggers a direct download (Web) or share (Mobile)
  static Future<void> exportToCsv({
    required Client client,
    required List<Session> sessions,
    required Map<String, double> rateMap,
    required DateTime monthDate,
  }) async {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Date',
      'Service & Time',
      'Hour',
      'Rate Details (Tk)',
      'Type',
      'Status',
      'Bill (Tk)',
    ]);

    double totalBill = 0;
    double totalHours = 0;
    int completedCount = 0;
    int clientCancelledCount = 0;
    int centerCancelledCount = 0;

    for (final s in sessions) {
      double sessionBill = 0;
      String ratesDisplay = 'N/A';

      // Format services with AM/PM for CSV
      String servicesWithTime = s.services
          .map((sv) {
            return '${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)} ${sv.type}';
          })
          .join('; ');

      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        if (s.status == SessionStatus.completed) completedCount++;
        totalHours += s.totalDuration;
        for (var service in s.services) {
          final rate = rateMap[service.type] ?? 0.0;
          sessionBill += service.duration * rate;
        }
        ratesDisplay = s.services
            .map(
              (sv) =>
                  '${sv.type}: ${_currencyFormat.format(rateMap[sv.type] ?? 0)}',
            )
            .toSet()
            .join('; ');
      } else if (s.status == SessionStatus.cancelledCenter) {
        centerCancelledCount++;
      } else if (s.status == SessionStatus.cancelledClient) {
        clientCancelledCount++;
      }

      totalBill += sessionBill;

      // Derived Type display from individual services
      final typesDisplay = s.services
          .map((sv) => sv.sessionType.displayName)
          .toSet()
          .join('; ');

      rows.add([
        _dateFormat.format(s.date.toDate()),
        servicesWithTime,
        '${s.totalDuration}h',
        ratesDisplay,
        typesDisplay,
        s.status.displayName.toUpperCase(),
        sessionBill.toStringAsFixed(0),
      ]);
    }

    rows.add([]);
    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Total Hours:',
      totalHours.toStringAsFixed(1),
    ]);
    rows.add(['', '', '', '', '', 'Completed Sessions:', completedCount]);
    rows.add(['', '', '', '', '', 'Client Cancelled:', clientCancelledCount]);
    rows.add(['', '', '', '', '', 'Center Cancelled:', centerCancelledCount]);
    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Total Monthly Bill:',
      totalBill.toStringAsFixed(0),
    ]);
    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Current Balance:',
      client.walletBalance.toStringAsFixed(0),
    ]);
    rows.add([
      '',
      '',
      '',
      '',
      '',
      'Remaining Balance:',
      (client.walletBalance - totalBill).toStringAsFixed(0),
    ]);

    String csvData = const ListToCsvConverter().convert(rows);
    final safeName = client.name
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final fileName =
        '${safeName}_${DateFormat('MMMM_yyyy').format(monthDate)}.csv';

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
      ], text: 'Billing Export for ${client.name}');
    }
  }

  /// Generates a professional PDF Invoice document
  static pw.Document _buildInvoiceDocument({
    required Client client,
    required List<Session> sessions,
    required Map<String, double> rateMap,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) {
    final pdf = pw.Document();
    final netBalance = client.walletBalance - totalMonthlyBill;

    double totalHours = 0;
    int completedCount = 0;
    int clientCancelledCount = 0;
    int centerCancelledCount = 0;

    for (var s in sessions) {
      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        if (s.status == SessionStatus.completed) completedCount++;
        totalHours += s.totalDuration;
      } else if (s.status == SessionStatus.cancelledCenter) {
        centerCancelledCount++;
      } else if (s.status == SessionStatus.cancelledClient) {
        clientCancelledCount++;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(client, monthDate),
          pw.SizedBox(height: 20),
          _buildInvoiceInfo(client, monthDate),
          pw.SizedBox(height: 20),
          _buildSessionsTable(sessions, rateMap),
          pw.SizedBox(height: 20),
          _buildSummary(
            client: client,
            totalBill: totalMonthlyBill,
            netBalance: netBalance,
            totalHours: totalHours,
            completedCount: completedCount,
            clientCancelledCount: clientCancelledCount,
            centerCancelledCount: centerCancelledCount,
          ),
          _buildFooter(),
        ],
      ),
    );
    return pdf;
  }

  /// Generates a professional PDF Invoice and triggers download (Web) or layout/print (Mobile)
  static Future<void> generateInvoicePdf({
    required Client client,
    required List<Session> sessions,
    required Map<String, double> rateMap,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      rateMap: rateMap,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
    );

    final safeName = client.name
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final fileName =
        '${safeName}_${DateFormat('MMMM_yyyy').format(monthDate)}.pdf';

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

  /// Directly opens the print dialog for the invoice
  static Future<void> printInvoice({
    required Client client,
    required List<Session> sessions,
    required Map<String, double> rateMap,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      rateMap: rateMap,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
    );

    final safeName = client.name
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final fileName =
        '${safeName}_${DateFormat('MMMM_yyyy').format(monthDate)}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  /// Directly triggers the share sheet for the invoice (Mobile only)
  static Future<void> shareInvoice({
    required Client client,
    required List<Session> sessions,
    required Map<String, double> rateMap,
    required DateTime monthDate,
    required double totalMonthlyBill,
  }) async {
    final pdf = _buildInvoiceDocument(
      client: client,
      sessions: sessions,
      rateMap: rateMap,
      monthDate: monthDate,
      totalMonthlyBill: totalMonthlyBill,
    );

    final bytes = await pdf.save();
    final safeName = client.name
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final fileName =
        '${safeName}_${DateFormat('MMMM_yyyy').format(monthDate)}.pdf';

    if (kIsWeb) {
      await generateInvoicePdf(
        client: client,
        sessions: sessions,
        rateMap: rateMap,
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

  static pw.Widget _buildHeader(Client client, DateTime monthDate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CENTER ASSISTANT',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
            pw.Text('Professional Center Management System'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Date: ${DateFormat('dd MMM, yyyy').format(DateTime.now())}',
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(Client client, DateTime monthDate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BILL TO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              client.name,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Client ID: ${client.clientId}'),
            pw.Text('Contact: ${client.mobileNo}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'BILLING PERIOD:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              DateFormat('MMMM yyyy').format(monthDate).toUpperCase(),
              style: pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSessionsTable(
    List<Session> sessions,
    Map<String, double> rateMap,
  ) {
    final headers = [
      'Date',
      'Service (Time)',
      'Hours',
      'Rate (Tk)',
      'Type',
      'Status',
      'Total (Tk)',
    ];

    final data = sessions.map((s) {
      double sessionBill = 0;
      if (s.status == SessionStatus.completed ||
          s.status == SessionStatus.scheduled) {
        for (var service in s.services) {
          sessionBill += service.duration * (rateMap[service.type] ?? 0.0);
        }
      }

      // Format services with AM/PM for PDF table
      String servicesWithTime = s.services
          .map((sv) {
            return '${AddScheduleUtils.formatTimeToAmPm(sv.startTime)}-${AddScheduleUtils.formatTimeToAmPm(sv.endTime)} ${sv.type}';
          })
          .join('\n');

      final typesDisplay = s.services
          .map((sv) => sv.sessionType.displayName)
          .toSet()
          .join('\n');

      return [
        _dateFormat.format(s.date.toDate()),
        servicesWithTime,
        '${s.totalDuration}h',
        s.services
            .map((sv) => _currencyFormat.format(rateMap[sv.type] ?? 0))
            .toSet()
            .join('\n'),
        typesDisplay,
        s.status.displayName,
        _currencyFormat.format(sessionBill),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerLeft,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary({
    required Client client,
    required double totalBill,
    required double netBalance,
    required double totalHours,
    required int completedCount,
    required int clientCancelledCount,
    required int centerCancelledCount,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            children: [
              _summaryRow('Total Hours:', '${totalHours.toStringAsFixed(1)} h'),
              _summaryRow('Completed Sessions:', '$completedCount'),
              _summaryRow('Client Cancelled:', '$clientCancelledCount'),
              _summaryRow('Center Cancelled:', '$centerCancelledCount'),
              pw.SizedBox(height: 5),
              pw.Divider(),
              _summaryRow(
                'Current Prepaid Balance:',
                'Tk ${_currencyFormat.format(client.walletBalance)}',
              ),
              _summaryRow(
                'Total Monthly Bill:',
                '- Tk ${_currencyFormat.format(totalBill)}',
                color: PdfColors.red,
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: _summaryRow(
                  'Net Remaining Balance:',
                  'Tk ${_currencyFormat.format(netBalance)}',
                  isBold: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 40),
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Text(
            'Thank you for choosing Center Assistant.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'This is a computer-generated invoice and does not require a physical signature.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
