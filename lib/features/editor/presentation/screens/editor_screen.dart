import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final imageId = // سنقرأ الـ id لاحقاً من الرابط
        ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('محرر المستند')),
      body: Center(
        child: Text('جاري تطوير المحرر...\nمعرف الصورة: $imageId'),
      ),
    );
  }
}