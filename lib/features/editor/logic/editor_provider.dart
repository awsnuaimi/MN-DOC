import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditorProvider extends ChangeNotifier {
  final List<TextItem> _texts = [];
  List<TextItem> get texts => _texts;

  ImageProvider? _signatureImage;
  ImageProvider? get signatureImage => _signatureImage;

  Offset _signaturePosition = const Offset(50, 200);
  Offset get signaturePosition => _signaturePosition;
  double _signatureScale = 1.0;
  double get signatureScale => _signatureScale;

  void addText(String text, Offset position) {
    _texts.add(TextItem(text: text, position: position));
    notifyListeners();
  }

  void updateTextPosition(int index, Offset newPosition) {
    _texts[index].position = newPosition;
    notifyListeners();
  }

  void setSignature(ImageProvider? image) {
    _signatureImage = image;
    notifyListeners();
  }

  void updateSignaturePosition(Offset newPosition) {
    _signaturePosition = newPosition;
    notifyListeners();
  }

  void updateSignatureScale(double newScale) {
    _signatureScale = newScale;
    notifyListeners();
  }

  // دمج الصورة مع النصوص والتوقيع
  Future<String?> saveMergedImage(String backgroundPath) async {
    try {
      // تحميل الصورة الخلفية
      final backgroundBytes = await File(backgroundPath).readAsBytes();
      final backgroundImage = img.decodeImage(backgroundBytes);
      if (backgroundImage == null) return null;

      // رسم النصوص
      for (final textItem in _texts) {
        // نستخدم مكتبة image لرسم النص (بسيط)
        img.drawString(
          backgroundImage,
          textItem.text,
          x: textItem.position.dx.toInt(),
          y: textItem.position.dy.toInt(),
          color: img.ColorRgb8(0, 0, 0),
        );
      }

      // رسم التوقيع (إذا وجد)
      if (_signatureImage != null) {
        // تحويل ImageProvider إلى bytes
        final uiImage = await _imageProviderToUiImage(_signatureImage!);
        final signatureBytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (signatureBytes != null) {
          final signatureImage = img.decodeImage(signatureBytes.buffer.asUint8List());
          if (signatureImage != null) {
            img.compositeImage(
              backgroundImage,
              signatureImage,
              dstX: _signaturePosition.dx.toInt(),
              dstY: _signaturePosition.dy.toInt(),
            );
          }
        }
      }

      // حفظ الصورة النهائية
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File(p.join(appDir.path, fileName));
      await savedFile.writeAsBytes(img.encodeJpg(backgroundImage));
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  // دالة مساعدة لتحويل ImageProvider إلى ui.Image
  Future<ui.Image> _imageProviderToUiImage(ImageProvider provider) async {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));
    return completer.future;
  }
}

class TextItem {
  String text;
  Offset position;
  TextItem({required this.text, required this.position});
}