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

  double _displayWidth = 0;
  double _displayHeight = 0;

  void setDisplaySize(double width, double height) {
    _displayWidth = width;
    _displayHeight = height;
  }

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

  void addRecognizedTexts(String fullText) {
    if (fullText.isEmpty) return;
    final lines = fullText.split('\n');
    double yOffset = 100;
    for (final line in lines) {
      if (line.trim().isEmpty) {
        yOffset += 30;
        continue;
      }
      _texts.add(TextItem(
        text: line.trim(),
        position: Offset(50, yOffset),
        fontSize: _textSize,
        color: _textColor,
      ));
      yOffset += 40;
    }
    notifyListeners();
  }

  Future<String?> saveMergedImage(String backgroundPath) async {
    try {
      final backgroundBytes = await File(backgroundPath).readAsBytes();
      final backgroundImage = img.decodeImage(backgroundBytes);
      if (backgroundImage == null) return null;

      final imgWidth = backgroundImage.width.toDouble();
      final imgHeight = backgroundImage.height.toDouble();

      double scaleX = 1.0;
      double scaleY = 1.0;
      if (_displayWidth > 0 && _displayHeight > 0) {
        scaleX = imgWidth / _displayWidth;
        scaleY = imgHeight / _displayHeight;
      }

      for (final textItem in _texts) {
        final colorInt = img.ColorRgb8(
          textItem.color.red,
          textItem.color.green,
          textItem.color.blue,
        );
        final adjustedX = (textItem.position.dx * scaleX).toInt();
        final adjustedY = (textItem.position.dy * scaleY).toInt();
        img.drawString(
          backgroundImage,
          textItem.text,
          font: img.arial24,
          x: adjustedX,
          y: adjustedY,
          color: colorInt,
        );
      }

      if (_signatureBytes != null) {
        var signatureImg = img.decodeImage(_signatureBytes!);
        if (signatureImg != null) {
          if (_signatureScale != 1.0) {
            final newW = (signatureImg.width * _signatureScale).round();
            final newH = (signatureImg.height * _signatureScale).round();
            signatureImg = img.copyResize(signatureImg, width: newW, height: newH);
          }
          final adjustedSigX = (_signaturePosition.dx * scaleX).toInt();
          final adjustedSigY = (_signaturePosition.dy * scaleY).toInt();
          img.compositeImage(
            backgroundImage,
            signatureImg,
            dstX: adjustedSigX,
            dstY: adjustedSigY,
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