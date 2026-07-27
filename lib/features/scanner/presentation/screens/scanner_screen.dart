import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';   // <-- أضف هذا الاستيراد
import '../../logic/scanner_provider.dart';
import 'dart:io';

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
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _showImageSourceDialog(context),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.images.isEmpty
              ? const Center(
                  child: Text('لا توجد صور ممسوحة. اضغط على أيقونة الكاميرا للبدء.'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.images.length,
                  itemBuilder: (context, index) {
                    final image = provider.images[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(image.filePath),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                image.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => provider.deleteImage(index),
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScannerProvider>().pickImage(ImageSource.camera);
            },
            child: const Text('الكاميرا'),
          ),
          TextButton(
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