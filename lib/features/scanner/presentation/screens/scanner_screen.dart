import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/scanner_provider.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScannerProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('الماسح الضوئي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded),
            onPressed: () => context.read<ScannerProvider>().pickFile(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            onPressed: () => _showImageSourceDialog(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.images.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('لا توجد صور ممسوحة', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('اضغط على أيقونة الكاميرا للبدء', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: provider.images.length,
                  itemBuilder: (context, index) {
                    final image = provider.images[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          image.filePath.toLowerCase().endsWith('.pdf')
                              ? Center(child: Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.red[300]))
                              : Image.file(File(image.filePath), fit: BoxFit.cover),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(image.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                                onPressed: () => provider.softDeleteImage(image.id!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('اختر المصدر'),
        content: const Text('حدد مصدر الصورة'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScannerProvider>().pickImage(ImageSource.camera);
            },
            child: const Text('الكاميرا'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScannerProvider>().pickImage(ImageSource.gallery);
            },
            child: const Text('المعرض'),
          ),
        ],
      ),
    );
  }
}