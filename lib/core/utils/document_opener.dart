import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../features/pdf_form/logic/pdf_form_service.dart';

/// يقرر أفضل طريقة لفتح مستند:
/// - صورة عادية → المحرر الحالي مباشرة.
/// - PDF فيه حقول تفاعلية (AcroForm) → شاشة تعبئة النموذج.
/// - PDF بدون حقول (ممسوح/مسطّح) → تحويل أول صفحة لصورة وفتحها
///   بالمحرر الحالي (نص/توقيع)، بدل الاكتفاء بخيار "مشاركة" فقط.
class DocumentOpener {
  static Future<void> open(BuildContext context, String filePath) async {
    if (!File(filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الملف غير موجود')));
      return;
    }

    if (!filePath.toLowerCase().endsWith('.pdf')) {
      context.push('/editor', extra: filePath);
      return;
    }

    bool hasFields = false;
    try {
      hasFields = await PdfFormService().hasFillableFields(filePath);
    } catch (_) {
      hasFields = false;
    }
    if (!context.mounted) return;

    if (hasFields) {
      context.push('/pdf-form', extra: filePath);
      return;
    }

    try {
      final bytes = await File(filePath).readAsBytes();
      final pages = Printing.raster(bytes, pages: [0], dpi: 200);
      final page = await pages.first;
      final imageBytes = await page.toPng();
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(imagePath).writeAsBytes(imageBytes.toList());
      if (!context.mounted) return;
      context.push('/editor', extra: imagePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر فتح هذا الملف للتحرير')));
      }
    }
  }
}