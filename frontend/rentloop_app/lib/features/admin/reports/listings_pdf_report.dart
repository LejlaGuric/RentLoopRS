import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/admin_listing_list_item.dart';

class ListingsPdfReport {
  Future<void> generate(List<AdminListingListItem> listings) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final generated =
        '${now.day}.${now.month}.${now.year}. ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Text(
            'RentLoop - Listings Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: PdfColors.grey200,
            child: pw.Text(
              'Stanovi koji su trenutno aktivni na platformi',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: $generated',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Total listings: ${listings.length}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),

          pw.LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints!.maxWidth;

              final nameWidth = totalWidth * 0.34;
              final cityWidth = totalWidth * 0.22;
              final typeWidth = totalWidth * 0.18;
              final priceWidth = totalWidth * 0.13;
              final ratingWidth = totalWidth * 0.13;

              return pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
                columnWidths: {
                  0: pw.FixedColumnWidth(nameWidth),
                  1: pw.FixedColumnWidth(cityWidth),
                  2: pw.FixedColumnWidth(typeWidth),
                  3: pw.FixedColumnWidth(priceWidth),
                  4: pw.FixedColumnWidth(ratingWidth),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _headerCell('Naziv'),
                      _headerCell('Grad'),
                      _headerCell('Tip'),
                      _headerCell('Cijena'),
                      _headerCell('Ocjena'),
                    ],
                  ),
                  ...listings.map(
                    (l) => pw.TableRow(
                      children: [
                        _dataCell(_shorten(l.name, 28)),
                        _dataCell(_shorten(l.city, 18)),
                        _dataCell(_shorten(l.rentType, 14)),
                        _dataCell(l.pricePerNight.toStringAsFixed(2)),
                        _dataCell(l.avgRating.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _dataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        maxLines: 1,
      ),
    );
  }

  String _shorten(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}...';
  }
}