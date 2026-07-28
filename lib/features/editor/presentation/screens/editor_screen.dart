import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../logic/editor_provider.dart';
import '../../../scanner/logic/scanner_provider.dart';
import '../../../scanner/data/models/scanned_image.dart';
import '../widgets/signature_pad.dart';

class EditorScreen extends StatefulWidget {
  final String? imageId; // سيكون filePath
  const EditorScreen({super.key, this.imageId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _textController = TextEditingController();
  String? backgroundImagePath;
  bool _isSaving = false;
  bool _loadingFailed = false;

  // أبعاد العرض الحالية للصورة (ستُحدّث من LayoutBuilder)
  double displayWidth = 0;
  double displayHeight = 0;

  @override
  void initState() {
    super.initState();
    if (widget.imageId != null && widget.imageId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImageByPath(widget.imageId!);
      });
    } else {
      setState(() {
        _loadingFailed = true;
      });
    }
  }

  void _loadImageByPath(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      if (!mounted) return;
      setState(() {
        backgroundImagePath = filePath;
        _loadingFailed = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _loadingFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف الصورة غير موجود على الجهاز')),
      );
    }
  }

  Future<void> _saveMergedImage() async {
    if (backgroundImagePath == null) return;
    if (!_isImageFile(backgroundImagePath!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التعديل متاح للصور فقط')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final editor = context.read<EditorProvider>();
    // تحديث أبعاد العرض في الـ provider قبل الحفظ
    editor.setDisplaySize(displayWidth, displayHeight);
    final newPath = await editor.saveMergedImage(backgroundImagePath!);
    if (!mounted) return;

    if (newPath != null) {
      final scanner = context.read<ScannerProvider>();
      final oldImage = scanner.images.firstWhere(
        (img) => img.filePath == backgroundImagePath,
        orElse: () => ScannedImage(filePath: '', title: ''),
      );
      if (oldImage.id != null) {
        final updatedImage = oldImage.copyWith(filePath: newPath);
        await scanner.updateImage(updatedImage);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الحفظ')),
      );
    }
    setState(() => _isSaving = false);
  }

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'bmp'].contains(extension);
  }

  // ... دوال التصدير والمشاركة والقص (لم تتغير) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر المستند'),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: _cropImage,
            tooltip: 'قص الصورة',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveMergedImage,
            tooltip: 'حفظ',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isImageFile(backgroundImagePath ?? '') && backgroundImagePath != null
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    onPressed: _showAddTextDialog,
                    tooltip: 'إضافة نص',
                  ),
                  IconButton(
                    icon: const Icon(Icons.draw),
                    onPressed: _showSignaturePad,
                    tooltip: 'توقيع',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareDocument,
                    tooltip: 'مشاركة',
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: _exportToPdf,
                    tooltip: 'PDF',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loadingFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('تعذر تحميل المستند', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع'),
            ),
          ],
        ),
      );
    }

    if (backgroundImagePath == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل المستند...'),
          ],
        ),
      );
    }

    if (!_isImageFile(backgroundImagePath!)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'هذا النوع من الملفات لا يمكن تحريره حالياً',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _shareDocument,
              icon: const Icon(Icons.share),
              label: const Text('مشاركة الملف'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // تحديث أبعاد العرض في كل مرة تتغير فيها الشجرة
        displayWidth = constraints.maxWidth;
        displayHeight = constraints.maxHeight;

        final editor = context.watch<EditorProvider>();
        return Stack(
          children: [
            Image.file(
              File(backgroundImagePath!),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
            if (editor.signatureImage != null)
              Positioned(
                left: editor.signaturePosition.dx,
                top: editor.signaturePosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    editor.updateSignaturePosition(
                      Offset(
                        editor.signaturePosition.dx + details.delta.dx,
                        editor.signaturePosition.dy + details.delta.dy,
                      ),
                    );
                  },
                  child: Image(image: editor.signatureImage!),
                ),
              ),
            ...editor.texts.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Positioned(
                left: item.position.dx,
                top: item.position.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    editor.updateTextPosition(
                      index,
                      Offset(
                        item.position.dx + details.delta.dx,
                        item.position.dy + details.delta.dy,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.white70,
                    child: Text(item.text,
                        style: TextStyle(fontSize: item.fontSize, color: item.color)),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ... دوال إضافة النص والتوقيع (لم تتغير) ...

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}