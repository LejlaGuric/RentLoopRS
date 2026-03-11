import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/admin_user.dart';

class AdminUsersPdfReport {
  Future<void> generate(List<AdminUser> users) async {
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
            'RentLoop - Users Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: $generated',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Total users: ${users.length}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints!.maxWidth;

              final usernameWidth = totalWidth * 0.18;
              final emailWidth = totalWidth * 0.26;
              final fullNameWidth = totalWidth * 0.20;
              final roleWidth = totalWidth * 0.12;
              final activeWidth = totalWidth * 0.10;
              final phoneWidth = totalWidth * 0.14;

              return pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
                columnWidths: {
                  0: pw.FixedColumnWidth(usernameWidth),
                  1: pw.FixedColumnWidth(emailWidth),
                  2: pw.FixedColumnWidth(fullNameWidth),
                  3: pw.FixedColumnWidth(roleWidth),
                  4: pw.FixedColumnWidth(activeWidth),
                  5: pw.FixedColumnWidth(phoneWidth),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _headerCell('Username'),
                      _headerCell('Email'),
                      _headerCell('Ime i prezime'),
                      _headerCell('Role'),
                      _headerCell('Aktivan'),
                      _headerCell('Telefon'),
                    ],
                  ),
                  ...users.map(
                    (u) => pw.TableRow(
                      children: [
                        _dataCell(_shorten(u.username, 20)),
                        _dataCell(_shorten(u.email, 30)),
                        _dataCell(_shorten(u.fullName, 24)),
                        _dataCell(_shorten(u.roleText, 12)),
                        _dataCell(u.isActive ? 'DA' : 'NE'),
                        _dataCell(_shorten(u.phone ?? '-', 18)),
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