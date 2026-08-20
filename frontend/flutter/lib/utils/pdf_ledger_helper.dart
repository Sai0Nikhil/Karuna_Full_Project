import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/case_model.dart';
import '../services/donation_service.dart';

class PdfLedgerHelper {
  static Future<void> generateAndPrintLedger(CaseModel c) async {
    final donations = await DonationService.getDonationsForCase(c.id);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0F766E'), // Teal
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('KARUNA ANIMAL RESCUE', style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('DONATION AUDIT & VET LEDGER REPORT', style: pw.TextStyle(color: PdfColor.fromHex('#E2E8F0'), fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Metadata
              pw.Text('CASE REPORT #K${c.id.toString().padLeft(3, '0')}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Species: ${c.species ?? "Unknown"}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Condition: ${c.probableCondition ?? "Unknown"}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Location: ${c.locationLabel ?? "Unknown"}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Status: ${(c.status ?? "reported").toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('NGO Partner: ${c.ngo ?? "Karuna Volunteers"}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Estimated Cost: INR ${c.estimatedCostInr ?? 0}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 12),

              // Donations Table
              pw.Text('DONATIONS RECEIVED', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B'))),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Donor Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Payment Method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Offset Target', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  // Table Rows
                  ...donations.map((d) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d.donorName, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${d.amountInr}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d.paymentMethod ?? 'UPI', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(d.billOffsetDetails ?? 'General Care', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 12),

              // Total Raised
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Donations Raised:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('INR ${donations.fold(0, (sum, d) => sum + d.amountInr)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E'))),
                ],
              ),
              pw.Spacer(),

              // Footer Stamp
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#0F766E'), width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'This is a system-generated, secure audit log from the Karuna rescue portal. Donations are exempt under section 80G.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('#475569')),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Karuna_Ledger_Case_${c.id}.pdf',
    );
  }
}
