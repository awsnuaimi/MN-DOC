import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/scanner_provider.dart';
import '../../data/models/scanned_image.dart';
import '../../../../core/constants/app_colors.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  void _openDocument(BuildContext context, ScannedImage image) {
    if (!File(image.filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف المستند غير موجود')),
      );
      return;
    }
    context.push('/editor', extra: image.filePath);
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('مسح ذكي', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('كشف حواف تلقائي وتصحيح منظور'),
              onTap: () {
                Navigator.pop(context);
                context.read<ScannerProvider>().scanWithDocScanner();
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.lightWash, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              title: const Text('كاميرا عادية'),
              onTap: () {
                Navigator.pop(context);
                context.read<ScannerProvider>().pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.lightWash, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.photo_library_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(context);
                context.read<ScannerProvider>().pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScannerProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'الماسح الضوئي',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: Colors.white),
                  onPressed: () => context.read<ScannerProvider>().pickFile(),
                  tooltip: 'إضافة ملف',
                ),
                IconButton(
                  icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                  onPressed: provider.isScanning ? null : () => _showScanOptions(context),
                  tooltip: 'مسح جديد',
                ),
              ],
            ),
          ),
          if (provider.isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.images.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.document_scanner_outlined,
                                  size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
                              const SizedBox(height: 16),
                              Text('لا توجد صور ممسوحة',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                              const SizedBox(height: 8),
                              Text('اضغط على أيقونة الكاميرا للبدء بمسح ذكي',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
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
                          return GestureDetector(
                            onTap: () => _openDocument(context, image),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  image.filePath.toLowerCase().endsWith('.pdf')
                                      ? Container(
                                          color: AppColors.lightWash,
                                          child: Center(
                                              child: Icon(Icons.picture_as_pdf_rounded,
                                                  size: 44, color: Colors.red[300])),
                                        )
                                      : Image.file(File(image.filePath), fit: BoxFit.cover),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(image.title,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}