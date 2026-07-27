import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  // دمج التوقيع فقط مع الصورة (النصوص مؤقتاً لا تدمج)
  Future<String?> saveMergedImage(String backgroundPath) async {
    try {
      final backgroundBytes = await File(backgroundPath).readAsBytes();
      final backgroundImage = img.decodeImage(backgroundBytes);
      if (backgroundImage == null) return null;

      if (_signatureImage != null) {
        final uiImage = await _imageProviderToUiImage(_signatureImage!);
        final signatureBytes =
            await uiImage.toByteData(format: ui.ImageByteFormat.png);
        if (signatureBytes != null) {
          final signatureImg =
              img.decodeImage(signatureBytes.buffer.asUint8List());
          if (signatureImg != null) {
            img.compositeImage(
              backgroundImage,
              signatureImg,
              dstX: _signaturePosition.dx.toInt(),
              dstY: _signaturePosition.dy.toInt(),
            );
          }
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File(p.join(appDir.path, fileName));
      await savedFile.writeAsBytes(img.encodeJpg(backgroundImage));
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

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