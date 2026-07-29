import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/editor_provider.dart';

/// المساحة التفاعلية للمحرر: الصورة + النصوص القابلة للسحب + التوقيع.
/// مسؤولة فقط عن العرض والتفاعل المباشر — منفصلة تماماً عن منطق
/// الحفظ/التصدير/OCR الموجود بالشاشة الأب.
class DocumentCanvas extends StatelessWidget {
  final String imagePath;
  const DocumentCanvas({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final editor = context.watch<EditorProvider>();
      // نبلغ EditorProvider بحجم العرض الفعلي، يُستخدم لاحقاً لحساب مقياس
      // التحويل بين الشاشة والصورة الأصلية عند الحفظ/التصدير.
      editor.setDisplaySize(constraints.maxWidth, constraints.maxHeight);

      return Stack(children: [
        Image.file(File(imagePath), fit: BoxFit.contain, width: double.infinity, height: double.infinity),
        if (editor.signatureImage != null)
          Positioned(
            left: editor.signaturePosition.dx,
            top: editor.signaturePosition.dy,
            child: GestureDetector(
              onPanUpdate: (d) => editor.updateSignaturePosition(
                  Offset(editor.signaturePosition.dx + d.delta.dx, editor.signaturePosition.dy + d.delta.dy)),
              child: Image(image: editor.signatureImage!),
            ),
          ),
        ...editor.texts.asMap().entries.map((e) => Positioned(
            left: e.value.position.dx,
            top: e.value.position.dy,
            child: GestureDetector(
              onPanUpdate: (d) => editor.updateTextPosition(
                  e.key, Offset(e.value.position.dx + d.delta.dx, e.value.position.dy + d.delta.dy)),
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.white70,
                child: Text(e.value.text, style: TextStyle(fontSize: e.value.fontSize, color: e.value.color)),
              ),
            )))
      ]);
    });
  }
}