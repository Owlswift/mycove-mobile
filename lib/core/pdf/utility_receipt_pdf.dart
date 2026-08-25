import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/utility_purchase.dart';

/// Receipts for utility purchases are composed fully client-side — every
/// field a receipt needs (token, units, meter/DISCO, provider ref) already
/// comes back on the purchase object from the API.
///
/// "Download" rides the system share sheet (`Printing.sharePdf`), which offers
/// Save-to-Files/Drive alongside WhatsApp/email — one code path covers both
/// downloading and forwarding the receipt.

// "NGN" rather than "₦" — the pdf package's built-in Times/Helvetica/
// Courier fonts have no glyph for the naira sign, so it silently rendered
// as a blank/missing-glyph box in the downloaded PDF (confirmed via the
// "Unable to find a font to draw '₦'" console warning). Pulling in a
// Unicode-capable font just for one symbol isn't worth the extra asset/
// network dependency (see PdfGoogleFonts) when plain ASCII already reads
// unambiguously as an amount.
String _naira(int amount) => 'NGN ${NumberFormat('#,##0').format(amount)}';

pw.Widget _row(String label, String value, {bool bold = false}) =>
    pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                font: bold ? pw.Font.timesBold() : null,
              ),
            ),
          ),
        ],
      ),
    );

Future<Uint8List> buildUtilityReceiptPdf({
  required UtilityPurchase purchase,
  required String residentName,
  required String house,
  String? phone,
}) {
  final isElectricity = purchase.type == 'ELECTRICITY';
  final statusLabel = switch (purchase.status) {
    UtilityPurchaseStatus.successful => 'SUCCESSFUL',
    UtilityPurchaseStatus.failed => 'FAILED',
    UtilityPurchaseStatus.pending => 'PENDING',
  };
  final dateLabel =
      DateFormat('d MMM yyyy · HH:mm').format(purchase.createdAt.toLocal());

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1B4332)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MyCove',
                  style: pw.TextStyle(
                    fontSize: 24,
                    font: pw.Font.timesBold(),
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  isElectricity
                      ? 'Electricity Purchase Receipt'
                      : 'Airtime Purchase Receipt',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _row('Reference', purchase.id),
          _row('Date', dateLabel),
          _row('Status', statusLabel, bold: true),
          if ((purchase.failureReason ?? '').isNotEmpty)
            _row('Failure reason', purchase.failureReason!),
          pw.SizedBox(height: 12),
          pw.Text(
            'CUSTOMER',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Divider(),
          _row('Name', residentName),
          if (house.isNotEmpty) _row('House', house),
          pw.SizedBox(height: 12),
          pw.Text(
            'TRANSACTION DETAILS',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Divider(),
          if (isElectricity) ...[
            if (purchase.meter != null) ...[
              _row('DISCO', purchase.meter!.discoName),
              _row('Meter number', purchase.meter!.meterNumber),
              _row(
                'Meter type',
                purchase.meter!.meterType.replaceAll('_', ' ').toUpperCase(),
              ),
            ],
            if ((purchase.phone ?? '').isNotEmpty)
              _row('Contact phone', purchase.phone!),
          ] else ...[
            if ((purchase.network ?? '').isNotEmpty)
              _row('Network', purchase.network!.toUpperCase()),
            _row('Recipient', phone ?? ''),
          ],
          _row('Amount paid', _naira(purchase.amount), bold: true),
          if ((purchase.provider ?? '').isNotEmpty)
            _row('Vend provider', purchase.provider!),
          if ((purchase.token ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFF1B4332),
                  width: 1.2,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PREPAID TOKEN',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    purchase.token!,
                    style:
                        pw.TextStyle(fontSize: 16, font: pw.Font.courierBold()),
                  ),
                  if ((purchase.units ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      [
                        purchase.units,
                        if ((purchase.tariff ?? '').isNotEmpty)
                          purchase.tariff!,
                      ].join('  ·  '),
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ],
              ),
            ),
          ],
          pw.Spacer(),
          pw.Divider(),
          pw.Text(
            'Generated by MyCove. Keep your prepaid token safe - it is required '
            'to load the units on your meter. For help, contact your estate '
            'management office.',
            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// Opens the share sheet with the generated PDF — its "Save to Files" action
/// is the download path, while WhatsApp/email cover forwarding.
Future<void> shareUtilityReceiptPdf({
  required UtilityPurchase purchase,
  required String residentName,
  required String house,
  String? phone,
}) async {
  final bytes = await buildUtilityReceiptPdf(
    purchase: purchase,
    residentName: residentName,
    house: house,
    phone: phone,
  );
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'mycove-receipt-${purchase.id}.pdf',
  );
}