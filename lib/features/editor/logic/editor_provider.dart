import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditorProvider extends ChangeNotifier {
  final List<TextItem> _texts = [];
  List<TextItem> get texts => _texts;

  ImageProvider? _signatureImage;
  ImageProvider? get signatureImage => _signatureImage;

  Uint8List? _signatureBytes;
  Uint8List? get signatureBytes => _signatureBytes;

  Offset _signaturePosition = const Offset(50, 200);
  Offset get signaturePosition => _signaturePosition;
  double _signatureScale = 1.0;
  double get signatureScale => _signatureScale;

  double _textSize = 18.0;
  double get textSize => _textSize;
  Color _textColor = Colors.black;
  Color get textColor => _textColor;

  void addText(String text, Offset position) {
    _texts.add(TextItem(
      text: text,
      position: position,
      fontSize: _textSize,
      color: _textColor,
    ));
    notifyListeners();
  }

  void updateTextPosition(int index, Offset newPosition) {
    _texts[index].position = newPosition;
    notifyListeners();
  }

  void setTextSize(double size) {
    _textSize = size;
    notifyListeners();
  }

  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
  }

  void setSignature(ImageProvider? image, Uint8List? bytes) {
    _signatureImage = image;
    _signatureBytes = bytes;
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

  Future<String?> saveMergedImage(String backgroundPath) async {
    try {
      final backgroundBytes = await File(backgroundPath).readAsBytes();
      final backgroundImage = img.decodeImage(backgroundBytes);
      if (backgroundImage == null) return null;

      // رسم النصوص باستخدام خط افتراضي (يدعم اللاتينية فقط)
      for (final textItem in _texts) {
        final colorInt = img.ColorRgb8(
          textItem.color.red,
          textItem.color.green,
          textItem.color.blue,
        );
        img.drawString(
          backgroundImage,
          textItem.text,
          font: img.arial24,
          x: textItem.position.dx.toInt(),
          y: textItem.position.dy.toInt(),
          color: colorInt,
        );
      }

      // رسم التوقيع
      if (_signatureBytes != null) {
        final signatureImg = img.decodeImage(_signatureBytes!);
        if (signatureImg != null) {
          img.compositeImage(
            backgroundImage,
            signatureImg,
            dstX: _signaturePosition.dx.toInt(),
            dstY: _signaturePosition.dy.toInt(),
          );
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
}

class TextItem {
  String text;
  Offset position;
  double fontSize;
  Color color;

  TextItem({
    required this.text,
    required this.position,
    this.fontSize = 18.0,
    this.color = Colors.black,
  });
}