import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/budget.dart';
import 'currency.dart';

/// Gera o PDF de um orçamento BOX JM — layout limpo, cabeçalho cromado
/// e tabela de serviços em estilo ticket.
Future<pw.Document> buildBudgetPdf(Budget budget) async {
  final doc = pw.Document();

  const ignition = PdfColor.fromInt(0xFFFF3B3B);
  const ignitionDeep = PdfColor.fromInt(0xFFB91C1C);
  const obsidian = PdfColor.fromInt(0xFF0E0E14);
  const textPrimary = PdfColor.fromInt(0xFF111114);
  const textSecondary = PdfColor.fromInt(0xFF4A4A52);
  const textMuted = PdfColor.fromInt(0xFF8B8B93);
  const surface = PdfColor.fromInt(0xFFF5F5F7);
  const border = PdfColor.fromInt(0xFFE4E4E7);

  final createdAt = DateFormat("dd/MM/yyyy 'às' HH:mm").format(budget.createdAt);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
      build: (ctx) => [
        _header(budget, createdAt, ignition, ignitionDeep, obsidian,
            textPrimary, textSecondary, textMuted),
        pw.SizedBox(height: 20),
        _infoBlocks(budget, textPrimary, textSecondary, textMuted, surface,
            border, ignition),
        pw.SizedBox(height: 22),
        _servicesTable(budget, textPrimary, textSecondary, textMuted, surface,
            border, ignition),
        pw.SizedBox(height: 18),
        _totalsBlock(budget, textPrimary, textSecondary, ignition, border,
            obsidian),
        if ((budget.notes ?? '').trim().isNotEmpty) ...[
          pw.SizedBox(height: 20),
          _notesBlock(budget.notes!, textPrimary, textMuted, surface, border),
        ],
        pw.SizedBox(height: 28),
        _footer(textMuted),
      ],
    ),
  );

  return doc;
}

pw.Widget _header(
  Budget budget,
  String createdAt,
  PdfColor ignition,
  PdfColor ignitionDeep,
  PdfColor obsidian,
  PdfColor textPrimary,
  PdfColor textSecondary,
  PdfColor textMuted,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      color: obsidian,
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 46,
          height: 46,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [ignition, ignitionDeep],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'JM',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'BOX',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'JM',
                    style: pw.TextStyle(
                      color: ignition,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Estética Automotiva',
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFFA1A1AA),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'ORÇAMENTO',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              createdAt,
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFFA1A1AA),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _infoBlocks(
  Budget b,
  PdfColor textPrimary,
  PdfColor textSecondary,
  PdfColor textMuted,
  PdfColor surface,
  PdfColor border,
  PdfColor ignition,
) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: _infoCard(
          title: 'CLIENTE',
          primary: b.clientName.isEmpty ? 'Sem nome' : b.clientName,
          secondary: b.clientPhone.isNotEmpty ? b.clientPhone : null,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          surface: surface,
          border: border,
        ),
      ),
      pw.SizedBox(width: 10),
      pw.Expanded(
        child: _infoCard(
          title: 'VEÍCULO',
          primary: '${b.vehicleBrand} ${b.vehicleModel}'.trim(),
          secondary: b.vehicleType.label,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          surface: surface,
          border: border,
        ),
      ),
    ],
  );
}

pw.Widget _infoCard({
  required String title,
  required String primary,
  required String? secondary,
  required PdfColor textPrimary,
  required PdfColor textSecondary,
  required PdfColor textMuted,
  required PdfColor surface,
  required PdfColor border,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: surface,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: border, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: textMuted,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          primary.isEmpty ? '—' : primary,
          style: pw.TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (secondary != null && secondary.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            secondary,
            style: pw.TextStyle(color: textSecondary, fontSize: 10),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _servicesTable(
  Budget b,
  PdfColor textPrimary,
  PdfColor textSecondary,
  PdfColor textMuted,
  PdfColor surface,
  PdfColor border,
  PdfColor ignition,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'SERVIÇOS',
        style: pw.TextStyle(
          color: textMuted,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: border, width: 0.5),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          children: [
            // Cabeçalho
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              decoration: pw.BoxDecoration(
                color: surface,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(10),
                  topRight: pw.Radius.circular(10),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text('Descrição',
                        style: pw.TextStyle(
                            color: textMuted,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                  pw.SizedBox(
                    width: 46,
                    child: pw.Text('Qtd',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            color: textMuted,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text('Valor',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            color: textMuted,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            // Linhas
            for (int i = 0; i < b.items.length; i++)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: i == 0
                        ? pw.BorderSide.none
                        : pw.BorderSide(color: border, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        b.items[i].serviceName,
                        style: pw.TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(
                      width: 46,
                      child: pw.Text(
                        '${b.items[i].quantity}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            color: textSecondary, fontSize: 11),
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        Currency.format(b.items[i].basePrice *
                            b.items[i].quantity *
                            b.multiplier),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: textPrimary,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _totalsBlock(
  Budget b,
  PdfColor textPrimary,
  PdfColor textSecondary,
  PdfColor ignition,
  PdfColor border,
  PdfColor obsidian,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 16),
    decoration: pw.BoxDecoration(
      color: obsidian,
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            pw.Text(
              Currency.format(b.total),
              style: pw.TextStyle(
                color: ignition,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _notesBlock(
  String notes,
  PdfColor textPrimary,
  PdfColor textMuted,
  PdfColor surface,
  PdfColor border,
) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: surface,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: border, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('OBSERVAÇÕES',
            style: pw.TextStyle(
                color: textMuted,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.5)),
        pw.SizedBox(height: 6),
        pw.Text(notes,
            style: pw.TextStyle(color: textPrimary, fontSize: 11, lineSpacing: 2)),
      ],
    ),
  );
}

pw.Widget _footer(PdfColor textMuted) {
  return pw.Center(
    child: pw.Column(
      children: [
        pw.Container(
          width: 60,
          height: 0.5,
          color: textMuted,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Obrigado pela preferência',
          style: pw.TextStyle(
              color: textMuted, fontSize: 9, letterSpacing: 1),
        ),
      ],
    ),
  );
}
