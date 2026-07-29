import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

/// قراءة النص من الصورة عبر Tesseract — يدعم العربية فعلياً (على عكس
/// google_mlkit_text_recognition السابق الذي كان Latin فقط).
/// المحرك يعمل بالكامل على الجهاز (offline)، مجاني تماماً.
class OcrService {
  Future<String> recognizeText(String imagePath) async {
    try {
      final config = OCRConfig(
        // عربي + لاتيني معاً: يغطي أرقام الفواتير والتواريخ الإنجليزية
        // الشائعة داخل مستندات عربية.
        language: 'ara+eng',
        engine: OCREngine.tesseract,
      );
      final text = await TesseractOcr.extractText(imagePath, config: config);
      return text.trim();
    } catch (e) {
      return '';
    }
  }

  /// لا موارد صريحة تحتاج تنظيفاً مع هذه الحزمة، لكن نُبقي الدالة
  /// للحفاظ على نفس الواجهة التي تستخدمها الشاشات (dispose عند الإغلاق).
  void dispose() {}
}