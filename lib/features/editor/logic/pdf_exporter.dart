import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'editor_provider.dart';

/// يفصل منطق بناء وتصدير PDF بالكامل عن شاشة المحرر — لا يحتاج BuildContext
/// ولا يعرف شيئاً عن الواجهة، فقط يبني الملف ويرسله للطباعة/المشاركة.
class PdfExporter {
  static Future<void> exportImageWithOverlays({
    required String imagePath,
    required EditorProvider editor,
  }) async {
    final bytes = await File(imagePath).readAsBytes();

    // خط Tajawal لدعم العربية الصحيح داخل ملف PDF
    final arabicFont = await PdfGoogleFonts.tajawalRegular();
    final arabicFontBold = await PdfGoogleFonts.tajawalBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
    );

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Stack(children: [
        pw.Positioned(
          left: 0,
          top: 0,
          child: pw.Image(pw.MemoryImage(bytes),
              fit: pw.BoxFit.contain, width: PdfPageFormat.a4.width, height: PdfPageFormat.a4.height),
        ),
        ...editor.texts.map((item) {
          final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(item.text);
          return pw.Positioned(
            left: item.position.dx,
            top: item.position.dy,
            child: pw.Text(
              item.text,
              textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: item.fontSize,
                color: PdfColor(item.color.red / 255, item.color.green / 255, item.color.blue / 255),
              ),
            ),
          );
        }),
        if (editor.signatureBytes != null)
          pw.Positioned(
            left: editor.signaturePosition.dx,
            top: editor.signaturePosition.dy,
            child: pw.Image(pw.MemoryImage(editor.signatureBytes!), width: 150),
          ),
      ]),
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}