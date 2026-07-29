import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../logic/editor_provider.dart';
import '../../logic/pdf_exporter.dart';
import '../../../scanner/logic/scanner_provider.dart';
import '../../../scanner/data/models/scanned_image.dart';
import '../widgets/signature_pad.dart';
import '../widgets/document_canvas.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/add_text_sheet.dart';
import '../../../../core/services/ocr_service.dart';

class EditorScreen extends StatefulWidget {
  final String? imageId;
  const EditorScreen({super.key, this.imageId});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final OcrService _ocrService = OcrService();
  String? backgroundImagePath;
  bool _isSaving = false;
  bool _loadingFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageId != null && widget.imageId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadImageByPath(widget.imageId!));
    } else {
      setState(() => _loadingFailed = true);
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  bool _isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'bmp'].contains(ext);
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
      setState(() => _loadingFailed = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ملف الصورة غير موجود على الجهاز')));
    }
  }

  Future<void> _saveMergedImage() async {
    if (backgroundImagePath == null) return;
    if (!_isImageFile(backgroundImagePath!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('التعديل متاح للصور فقط')));
      return;
    }
    setState(() => _isSaving = true);
    final editor = context.read<EditorProvider>();
    final newPath = await editor.saveMergedImage(backgroundImagePath!);
    if (!mounted) return;

    if (newPath != null) {
      final scanner = context.read<ScannerProvider>();
      final oldImage = scanner.images.firstWhere(
        (img) => img.filePath == backgroundImagePath,
        orElse: () => ScannedImage(filePath: '', title: ''),
      );
      if (oldImage.id != null) {
        await scanner.updateImage(oldImage.copyWith(filePath: newPath));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الحفظ')));
    }
    setState(() => _isSaving = false);
  }

  Future<void> _cropImage() async {
    if (backgroundImagePath == null) return;
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: backgroundImagePath!,
      aspectRatioPresets: [CropAspectRatioPreset.ratio4x3, CropAspectRatioPreset.ratio16x9],
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'قص الصورة', toolbarColor: Theme.of(context).primaryColor),
        IOSUiSettings(title: 'قص الصورة'),
      ],
    );
    if (croppedFile != null && mounted) setState(() => backgroundImagePath = croppedFile.path);
  }

  Future<void> _performOCR() async {
    if (backgroundImagePath == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري التعرف على النص...')));
    final text = await _ocrService.recognizeText(backgroundImagePath!);
    if (!mounted) return;
    if (text.isNotEmpty) {
      context.read<EditorProvider>().addRecognizedTexts(text);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم التعرف على ${text.split('\n').length} سطراً')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على نص في الصورة')));
    }
  }

  Future<void> _exportToPdf() async {
    if (backgroundImagePath == null) return;
    if (!_isImageFile(backgroundImagePath!)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('هذا الملف لا يمكن تحريره كصورة، جار مشاركته مباشرة')));
      Share.shareXFiles([XFile(backgroundImagePath!)]);
      return;
    }
    final editor = context.read<EditorProvider>();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تجهيز الخط العربي...'), duration: Duration(seconds: 2)),
      );
    }
    try {
      await PdfExporter.exportImageWithOverlays(imagePath: backgroundImagePath!, editor: editor);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
    }
  }

  void _shareDocument() async {
    if (backgroundImagePath == null) return;
    if (_isImageFile(backgroundImagePath!)) {
      final editor = context.read<EditorProvider>();
      final merged = await editor.saveMergedImage(backgroundImagePath!);
      Share.shareXFiles([XFile(merged ?? backgroundImagePath!)], text: 'مستند من MN Doc');
    } else {
      Share.shareXFiles([XFile(backgroundImagePath!)], text: 'مستند من MN Doc');
    }
  }

  void _showSignaturePad() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('توقيعك'),
        content: SignaturePadWidget(onSignatureSaved: (image, bytes) {
          context.read<EditorProvider>().setSignature(image, bytes);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showToolbar = _isImageFile(backgroundImagePath ?? '') && backgroundImagePath != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر المستند'),
        actions: [
          IconButton(icon: const Icon(Icons.crop_rounded), onPressed: _cropImage, tooltip: 'قص الصورة'),
          IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: _isSaving ? null : _saveMergedImage,
              tooltip: 'حفظ'),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: showToolbar
          ? EditorToolbar(actions: [
              ToolbarAction(
                icon: Icons.text_fields_rounded,
                label: 'نص',
                onTap: () => AddTextSheet.show(context, context.read<EditorProvider>()),
              ),
              ToolbarAction(icon: Icons.draw_rounded, label: 'توقيع', onTap: _showSignaturePad),
              ToolbarAction(icon: Icons.text_snippet_rounded, label: 'OCR', onTap: _performOCR),
              ToolbarAction(icon: Icons.share_rounded, label: 'مشاركة', onTap: _shareDocument),
              ToolbarAction(icon: Icons.picture_as_pdf_rounded, label: 'PDF', onTap: _exportToPdf, active: true),
            ])
          : null,
    );
  }

  Widget _buildBody() {
    if (_loadingFailed) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('تعذر تحميل المستند', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
        ]),
      );
    }
    if (backgroundImagePath == null) return const Center(child: CircularProgressIndicator());
    if (!_isImageFile(backgroundImagePath!)) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.insert_drive_file, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text('هذا النوع من الملفات لا يمكن تحريره حالياً', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: _shareDocument, icon: const Icon(Icons.share_rounded), label: const Text('مشاركة الملف')),
        ]),
      );
    }
    return DocumentCanvas(imagePath: backgroundImagePath!);
  }
}