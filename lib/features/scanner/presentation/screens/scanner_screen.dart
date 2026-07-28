import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/scanner_provider.dart';
import '../../../../core/constants/app_colors.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScannerProvider>();
    return Scaffold(
      body: Column(
        children: [
          // شريط علوي مخصص
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.gradientPrimary),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'الماسح الضوئي',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded,
                      color: Colors.white),
                  onPressed: () => context.read<ScannerProvider>().pickFile(),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white),
                  onPressed: () => _showImageSourceDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.images.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner_outlined,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد صور ممسوحة',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: provider.images.length,
                        itemBuilder: (context, index) {
                          final image = provider.images[index];
                          return _buildImageCard(image, provider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(
      ScannedImage image, ScannerProvider provider) {
    return GestureDetector(
      onTap: () {
        // يمكن فتح المحرر مباشرة
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              image.filePath.toLowerCase().endsWith('.pdf')
                  ? Center(
                      child: Icon(Icons.picture_as_pdf_rounded,
                          size: 48, color: Colors.red[300]),
                    )
                  : Image.file(File(image.filePath), fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: IconButton(
                    icon: const Icon(Icons.delete_rounded,
                        size: 16, color: Colors.red),
                    onPressed: () => provider.softDeleteImage(image.id!),
                  ),
                ),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
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