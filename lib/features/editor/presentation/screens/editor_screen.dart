import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../logic/editor_provider.dart';
import '../../../scanner/logic/scanner_provider.dart';
import '../../../scanner/data/models/scanned_image.dart';
import '../widgets/signature_pad.dart';

class EditorScreen extends StatefulWidget {
  final String? imageId;
  const EditorScreen({super.key, this.imageId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _textController = TextEditingController();
  String? backgroundImagePath;
  int? currentImageId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageId != null) {
      final id = int.tryParse(widget.imageId!);
      if (id != null) {
        currentImageId = id;
        // نحمّل المسار بعد بناء الواجهة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadImagePath(id);
        });
      }
    }
  }

  void _loadImagePath(int id) {
    final scannerProvider = context.read<ScannerProvider>();
    final image = scannerProvider.images.firstWhere(
      (img) => img.id == id,
      orElse: () => ScannedImage(filePath: '', title: ''),
    );
    if (image.filePath.isNotEmpty) {
      setState(() {
        backgroundImagePath = image.filePath;
      });
    }
  }

  Future<void> _saveMergedImage() async {
    if (backgroundImagePath == null || currentImageId == null) return;
    // إذا كان الملف ليس صورة، لا يمكن حفظ التعديلات عليه
    if (!_isImageFile(backgroundImagePath!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التعديل متاح للصور فقط')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final editor = context.read<EditorProvider>();
    final newPath = await editor.saveMergedImage(backgroundImagePath!);
    if (!mounted) return;

    if (newPath != null) {
      final scanner = context.read<ScannerProvider>();
      final oldImage = scanner.images.firstWhere(
        (img) => img.id == currentImageId,
        orElse: () => ScannedImage(filePath: '', title: ''),
      );
      if (oldImage.id != null) {
        final updatedImage = ScannedImage(
          id: oldImage.id,
          filePath: newPath,
          title: oldImage.title,
          createdAt: oldImage.createdAt,
        );
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

  Future<void> _exportToPdf() async {
    if (backgroundImagePath == null) return;
    if (!_isImageFile(backgroundImagePath!)) {
      // إذا كان PDF أو غيره، نشاركه مباشرة بدلاً من تصديره
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الملف لا يمكن تحريره كصورة، جار مشاركته مباشرة')),
      );
      Share.shareXFiles([XFile(backgroundImagePath!)]);
      return;
    }
    final editor = context.read<EditorProvider>();

    try {
      final backgroundBytes = await File(backgroundImagePath!).readAsBytes();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  top: 0,
                  child: pw.Image(
                    pw.MemoryImage(backgroundBytes),
                    fit: pw.BoxFit.contain,
                    width: PdfPageFormat.a4.width,
                    height: PdfPageFormat.a4.height,
                  ),
                ),
                ...editor.texts.map((item) {
                  return pw.Positioned(
                    left: item.position.dx,
                    top: item.position.dy,
                    child: pw.Text(
                      item.text,
                      style: pw.TextStyle(
                        fontSize: item.fontSize,
                        color: PdfColor(
                          item.color.red.toDouble() / 255,
                          item.color.green.toDouble() / 255,
                          item.color.blue.toDouble() / 255,
                        ),
                      ),
                    ),
                  );
                }),
                if (editor.signatureBytes != null)
                  pw.Positioned(
                    left: editor.signaturePosition.dx,
                    top: editor.signaturePosition.dy,
                    child: pw.Image(
                      pw.MemoryImage(editor.signatureBytes!),
                      width: 150,
                    ),
                  ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e')),
      );
    }
  }

  void _shareDocument() async {
    if (backgroundImagePath == null) return;
    if (_isImageFile(backgroundImagePath!)) {
      final editor = context.read<EditorProvider>();
      final mergedPath = await editor.saveMergedImage(backgroundImagePath!);
      final fileToShare = mergedPath ?? backgroundImagePath!;
      Share.shareXFiles([XFile(fileToShare)], text: 'مستند من MN Doc');
    } else {
      Share.shareXFiles([XFile(backgroundImagePath!)], text: 'مستند من MN Doc');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر المستند'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDocument,
            tooltip: 'مشاركة',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'تصدير إلى PDF',
          ),
          if (_isImageFile(backgroundImagePath ?? '')) ...[
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: _showAddTextDialog,
            ),
            IconButton(
              icon: const Icon(Icons.draw),
              onPressed: _showSignaturePad,
            ),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveMergedImage,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (backgroundImagePath == null) {
      return const Center(child: CircularProgressIndicator());
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
  }

  void _showAddTextDialog() {
    final editor = context.read<EditorProvider>();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('أضف نصاً'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(hintText: 'اكتب النص هنا'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('الحجم: '),
                    Expanded(
                      child: Slider(
                        value: editor.textSize,
                        min: 12,
                        max: 48,
                        divisions: 9,
                        label: editor.textSize.round().toString(),
                        onChanged: (val) {
                          editor.setTextSize(val);
                          setStateDialog(() {});
                        },
                      ),
                    ),
                    Text(editor.textSize.round().toString()),
                  ],
                ),
                Row(
                  children: [
                    const Text('اللون: '),
                    ...Colors.primaries.map((color) => GestureDetector(
                          onTap: () {
                            editor.setTextColor(color);
                            setStateDialog(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: editor.textColor == color
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    editor.addText(
                      _textController.text,
                      const Offset(50, 50),
                    );
                    _textController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSignaturePad() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('توقيعك'),
        content: SignaturePadWidget(
          onSignatureSaved: (image, bytes) {
            context.read<EditorProvider>().setSignature(image, bytes);
          },
        ),
      ),
    );
  }
}