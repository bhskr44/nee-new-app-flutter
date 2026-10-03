import 'package:flutter/material.dart' show BuildContext, Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';

/// Generates a branded estimate / quotation PDF for any calculator and opens
/// the system share sheet (WhatsApp, email, etc.).
///
/// Every PDF carries the app name, the user's name & phone number
/// ("Prepared by") and the same input/result rows shown in the app.
class EstimatePdfService {
  /// Keys checked (in order) to pick the grand-total row from [details].
  static const _totalKeys = [
    'Total Estimate', 'Total Construction Estimate', 'Net Payable Amount',
    'Total Cost', 'Est. Total Cost', 'Total with Labour', 'Total',
    'Rough Estimate', 'Est. Material Cost', 'Est. Cost', 'Estimated Cost',
  ];

  static Future<void> share({
    required BuildContext context,
    required String title,
    required Color accent,
    Map<String, String> specifications = const {},
    required Map<String, String> details,
    String? totalValue,
    String? extraNote,
  }) async {
    if (details.isEmpty) return;

    // "Prepared by" — the logged-in user's name and phone number
    final user = context.read<AuthProvider>().user;
    final preparedBy = _clean(user?.name ?? '').isNotEmpty && !(user?.name ?? '').startsWith('User ')
        ? user!.name
        : 'NEE App User';
    final phone = user?.phone ?? user?.profile?.phone;

    final now = DateTime.now();
    final refNo = 'NEE-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 100000}';
    final dateStr = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';

    final accentPdf = PdfColor.fromInt(0xFF000000 | (accent.toARGB32() & 0xFFFFFF));
    final accentLight = PdfColor(
      accentPdf.red + (1 - accentPdf.red) * 0.88,
      accentPdf.green + (1 - accentPdf.green) * 0.88,
      accentPdf.blue + (1 - accentPdf.blue) * 0.88,
    );

    String? total = totalValue;
    if (total == null) {
      for (final k in _totalKeys) {
        if (details.containsKey(k)) {
          total = details[k];
          break;
        }
      }
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            pw.Text(
              '* This quotation is an estimate only. Actual costs may vary depending on site conditions, '
              'material selection and installation charges. GST as applicable.'
              '${extraNote != null ? '\n* ${_clean(extraNote)}' : ''}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated with the ${AppConstants.appName} app',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic)),
          ],
        ),
        build: (_) => [
          // ── Header band: app name + quotation label ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: pw.BoxDecoration(color: accentPdf),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(AppConstants.appName,
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('Smart Construction Platform',
                      style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('QUOTATION / ESTIMATE',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('Ref: $refNo', style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // ── Title + date ──
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(_clean(title),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accentPdf)),
            pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
          pw.SizedBox(height: 10),
          // ── Prepared by: user name + phone number ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(children: [
              pw.Text('Prepared by:  ',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(_clean(preparedBy),
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              if (phone != null && phone.isNotEmpty) ...[
                pw.Text('   |   Phone:  ',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Text(_clean(phone),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ]),
          ),
          pw.SizedBox(height: 14),
          // ── Specifications (the inputs as entered in the app) ──
          if (specifications.isNotEmpty) ...[
            pw.Text('Specifications',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentPdf)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                children: specifications.entries
                    .map((e) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(_clean(e.key),
                                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                              pw.Text(_clean(e.value),
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          // ── Estimate details (the results as shown in the app) ──
          pw.Text('Estimate Details',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentPdf)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2)},
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentLight),
                children: [
                  _cell('Item', bold: true),
                  _cell('Value', bold: true, align: pw.TextAlign.right),
                ],
              ),
              ...details.entries.map((e) {
                final isTotal = total != null && e.value == total && _totalKeys.contains(e.key);
                return pw.TableRow(children: [
                  _cell(_clean(e.key), bold: isTotal),
                  _cell(_clean(e.value),
                      bold: isTotal,
                      align: pw.TextAlign.right,
                      color: isTotal ? accentPdf : PdfColors.black),
                ]);
              }),
            ],
          ),
          // ── Total highlight ──
          if (total != null) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: accentLight),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('TOTAL ESTIMATE',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accentPdf)),
                pw.Text(_clean(total),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: accentPdf)),
              ]),
            ),
          ],
        ],
      ),
    );

    final safeName = title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${safeName}_$refNo.pdf',
    );
  }

  /// The built-in PDF fonts (WinAnsi) can't render some glyphs used in the
  /// app UI — substitute safe equivalents.
  static String _clean(String s) => s
      .replaceAll('₹', 'Rs ')
      .replaceAll('★ ', '')
      .replaceAll('★', '')
      .replaceAll('≤', '<=')
      .replaceAll('—', '-');

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = PdfColors.black,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
        ),
      );
}
