import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../features/scanner/logic/scanner_provider.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ScannerProvider>().loadImages();
    });
  }

  void _showOptionsDialog(
      BuildContext context, int index, ScannerProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('إعادة تسمية'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, index, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, index, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, int index, ScannerProvider provider) {
    final controller =
        TextEditingController(text: provider.images[index].title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إعادة تسمية المستند'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'الاسم الجديد'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                provider.renameImage(index, newTitle);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, int index, ScannerProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المستند'),
        content: const Text('هل أنت متأكد من حذف هذا المستند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteImage(index);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MN Doc'),
      ),
      body: Consumer<ScannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.images.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'لا توجد مستندات بعد',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/scanner'),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('مسح مستند جديد'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
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
                child: InkWell(
                  onTap: () {
                    context.go('/editor?id=${image.id}');
                  },
                  onLongPress: () {
                    _showOptionsDialog(context, index, provider);
                  },
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/scanner'),
        child: const Icon(Icons.document_scanner),
      ),
    );
  }
}