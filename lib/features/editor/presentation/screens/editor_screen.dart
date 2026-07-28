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
import '../../../../core/services/ocr_service.dart';

class EditorScreen extends StatefulWidget {
  final String? imageId;
  const EditorScreen({super.key, this.imageId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _textController = TextEditingController();
  final OcrService _ocrService = OcrService();
  String? backgroundImagePath;
  bool _isSaving = false;
  bool _loadingFailed = false;
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
      setState(() => _loadingFailed = true);
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
      setState(() => _loadingFailed = true);
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
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'bmp'].contains(ext);
  }

  Future<void> _cropImage() async {
    if (backgroundImagePath == null) return;
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: backgroundImagePath!,
      aspectRatioPresets: [
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'قص الصورة',
          toolbarColor: Theme.of(context).primaryColor,
        ),
        IOSUiSettings(title: 'قص الصورة'),
      ],
    );
    if (croppedFile != null && mounted) {
      setState(() => backgroundImagePath = croppedFile.path);
    }
  }

  Future<void> _performOCR() async {
    if (backgroundImagePath == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري التعرف على النص...')),
    );
    final text = await _ocrService.recognizeText(backgroundImagePath!);
    if (!mounted) return;
    if (text.isNotEmpty) {
      context.read<EditorProvider>().addRecognizedTexts(text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم التعرف على ${text.split('\n').length} سطراً')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على نص في الصورة')),
      );
    }
  }

  Future<void> _exportToPdf() async {
    if (backgroundImagePath == null) return;
    if (!_isImageFile(backgroundImagePath!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الملف لا يمكن تحريره كصورة، جار مشاركته مباشرة')),
      );
      Share.shareXFiles([XFile(backgroundImagePath!)]);
      return;
    }
    final editor = context.read<EditorProvider>();
    try {
      final bytes = await File(backgroundImagePath!).readAsBytes();
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Stack(children: [
          pw.Positioned(
            left: 0, top: 0,
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain, width: PdfPageFormat.a4.width, height: PdfPageFormat.a4.height),
          ),
          ...editor.texts.map((item) => pw.Positioned(
            left: item.position.dx, top: item.position.dy,
            child: pw.Text(item.text, style: pw.TextStyle(fontSize: item.fontSize, color: PdfColor(item.color.red.toDouble()/255, item.color.green.toDouble()/255, item.color.blue.toDouble()/255))),
          )),
          if (editor.signatureBytes != null)
            pw.Positioned(left: editor.signaturePosition.dx, top: editor.signaturePosition.dy,
              child: pw.Image(pw.MemoryImage(editor.signatureBytes!), width: 150)),
        ]),
      ));
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
    }
  }

  void _shareDocument() async {
    if (backgroundImagePath == null) return;
    if (_isImageFile(backgroundImagePath!)) {
      final editor = context.read<EditorProvider>();
      final merged = await editor.saveMergedImage(backgroundImagePath!);
      final fileToShare = merged ?? backgroundImagePath!;
      Share.shareXFiles([XFile(fileToShare)], text: 'مستند من MN Doc');
    } else {
      Share.shareXFiles([XFile(backgroundImagePath!)], text: 'مستند من MN Doc');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر المستند'),
        actions: [
          IconButton(icon: const Icon(Icons.crop), onPressed: _cropImage, tooltip: 'قص الصورة'),
          IconButton(icon: const Icon(Icons.save), onPressed: _isSaving ? null : _saveMergedImage, tooltip: 'حفظ'),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _isImageFile(backgroundImagePath ?? '') && backgroundImagePath != null
          ? BottomAppBar(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(icon: const Icon(Icons.text_fields), onPressed: _showAddTextDialog, tooltip: 'إضافة نص'),
              IconButton(icon: const Icon(Icons.draw), onPressed: _showSignaturePad, tooltip: 'توقيع'),
              IconButton(icon: const Icon(Icons.text_snippet), onPressed: _performOCR, tooltip: 'تعرّف على النص (OCR)'),
              IconButton(icon: const Icon(Icons.share), onPressed: _shareDocument, tooltip: 'مشاركة'),
              IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportToPdf, tooltip: 'PDF'),
            ]))
          : null,
    );
  }

  Widget _buildBody() {
    if (_loadingFailed) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
      const SizedBox(height: 16),
      const Text('تعذر تحميل المستند', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
    ]));
    if (backgroundImagePath == null) return const Center(child: CircularProgressIndicator());
    if (!_isImageFile(backgroundImagePath!)) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.insert_drive_file, size: 80, color: Colors.grey[400]),
      const SizedBox(height: 20),
      Text('هذا النوع من الملفات لا يمكن تحريره حالياً', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _shareDocument, icon: const Icon(Icons.share), label: const Text('مشاركة الملف')),
    ]));

    return LayoutBuilder(builder: (context, constraints) {
      displayWidth = constraints.maxWidth;
      displayHeight = constraints.maxHeight;
      final editor = context.watch<EditorProvider>();
      return Stack(children: [
        Image.file(File(backgroundImagePath!), fit: BoxFit.contain, width: double.infinity, height: double.infinity),
        if (editor.signatureImage != null)
          Positioned(left: editor.signaturePosition.dx, top: editor.signaturePosition.dy,
            child: GestureDetector(
              onPanUpdate: (d) => editor.updateSignaturePosition(Offset(editor.signaturePosition.dx + d.delta.dx, editor.signaturePosition.dy + d.delta.dy)),
              child: Image(image: editor.signatureImage!),
            )),
        ...editor.texts.asMap().entries.map((e) => Positioned(
          left: e.value.position.dx, top: e.value.position.dy,
          child: GestureDetector(
            onPanUpdate: (d) => editor.updateTextPosition(e.key, Offset(e.value.position.dx + d.delta.dx, e.value.position.dy + d.delta.dy)),
            child: Container(padding: const EdgeInsets.all(4), color: Colors.white70,
              child: Text(e.value.text, style: TextStyle(fontSize: e.value.fontSize, color: e.value.color))),
          )))
      ]);
    });
  }

  void _showAddTextDialog() {
    final editor = context.read<EditorProvider>();
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setStateDialog) => AlertDialog(
      title: const Text('أضف نصاً'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _textController, decoration: const InputDecoration(hintText: 'اكتب النص هنا')),
        const SizedBox(height: 12),
        Row(children: [
          const Text('الحجم: '),
          Expanded(child: Slider(value: editor.textSize, min: 12, max: 48, divisions: 9, label: editor.textSize.round().toString(), onChanged: (v) { editor.setTextSize(v); setStateDialog((){}); })),
          Text(editor.textSize.round().toString()),
        ]),
        Row(children: [
          const Text('اللون: '),
          ...Colors.primaries.map((color) => GestureDetector(
            onTap: () { editor.setTextColor(color); setStateDialog((){}); },
            child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 24, height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: editor.textColor == color ? Border.all(color: Colors.black, width: 2) : null)),
          )),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(onPressed: () { if (_textController.text.isNotEmpty) { editor.addText(_textController.text, const Offset(50, 50)); _textController.clear(); Navigator.pop(context); } }, child: const Text('إضافة')),
      ],
    )));
  }

  void _showSignaturePad() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('توقيعك'),
      content: SignaturePadWidget(onSignatureSaved: (image, bytes) => context.read<EditorProvider>().setSignature(image, bytes)),
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}