import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../logic/editor_provider.dart';
import '../../../scanner/logic/scanner_provider.dart';
import '../../../scanner/data/models/scanned_image.dart';
import '../widgets/signature_pad.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _textController = TextEditingController();
  String? backgroundImagePath;
  int? currentImageId;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      final idString = route.settings.arguments as String?;
      if (idString != null) {
        final id = int.tryParse(idString);
        if (id != null && id != currentImageId) {
          currentImageId = id;
          _loadImagePath(id);
        }
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

  Future<void> _exportToPdf() async {
    if (backgroundImagePath == null) return;
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
                          fontSize: 14, color: PdfColors.black),
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

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر المستند'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'تصدير إلى PDF',
          ),
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
      ),
      body: backgroundImagePath == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  void _showAddTextDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('أضف نصاً'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(hintText: 'اكتب النص هنا'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                context.read<EditorProvider>().addText(
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