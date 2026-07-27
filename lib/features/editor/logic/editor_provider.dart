import 'package:flutter/material.dart';

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
}

class TextItem {
  String text;
  Offset position;
  TextItem({required this.text, required this.position});
}