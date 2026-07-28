import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../features/scanner/logic/scanner_provider.dart';
import '../../../../features/scanner/data/models/scanned_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScannerProvider>().loadImages();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDocument(ScannedImage image, ScannerProvider provider) {
    // التأكد من وجود الملف
    if (!File(image.filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف المستند غير موجود')),
      );
      return;
    }

    String docId;
    if (image.id != null) {
      docId = image.id.toString();
    } else {
      // نبحث عن الصورة بالقائمة عشان نلاقي id الحقيقي
      final realImage = provider.images.firstWhere(
        (img) => img.filePath == image.filePath,
        orElse: () => image,
      );
      if (realImage.id != null) {
        docId = realImage.id.toString();
      } else {
        // لا يوجد id حقيقي — لا يمكن فتح المحرر بأمان
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديد هوية المستند')),
        );
        return;
      }
    }

    // الانتقال إلى المحرر
    context.go('/editor', extra: docId);
  }

  void _showOptionsDialog(BuildContext context, ScannedImage image, ScannerProvider provider) {
    final isFavorite = image.isFavorite;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(isFavorite ? Icons.star : Icons.star_border),
              title: Text(isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleFavorite(image.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('إعادة تسمية'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, image, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(context);
                if (File(image.filePath).existsSync()) {
                  Share.shareXFiles([XFile(image.filePath)], text: 'مستند من MN Doc');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                provider.softDeleteImage(image.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم نقل المستند إلى سلة المهملات'),
                    action: SnackBarAction(
                      label: 'تراجع',
                      onPressed: () => provider.restoreImage(image.id!),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ScannedImage image, ScannerProvider provider) {
    final controller = TextEditingController(text: image.title);
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && image.id != null) {
                provider.renameImage(provider.images.indexOf(image), newTitle);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'الكل'),
            Tab(icon: Icon(Icons.star), text: 'المفضلة'),
            Tab(icon: Icon(Icons.delete), text: 'المهملات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsList(filter: 'all'),
          _buildDocumentsList(filter: 'favorites'),
          _buildDocumentsList(filter: 'deleted'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/scanner'),
        child: const Icon(Icons.document_scanner),
      ),
    );
  }

  Widget _buildDocumentsList({required String filter}) {
    return Consumer<ScannerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildShimmer();
        }

        List<ScannedImage> documents;
        switch (filter) {
          case 'favorites':
            documents = provider.favoriteImages;
            break;
          case 'deleted':
            documents = provider.deletedImages;
            break;
          default:
            documents = provider.images;
        }

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  filter == 'favorites'
                      ? 'لا توجد مفضلات'
                      : filter == 'deleted'
                          ? 'سلة المهملات فارغة'
                          : 'لا توجد مستندات بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final image = documents[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (image.isDeleted) {
                    _showDeletedOptions(context, image, provider);
                  } else {
                    _openDocument(image, provider);
                  }
                },
                onLongPress: () {
                  if (!image.isDeleted) {
                    _showOptionsDialog(context, image, provider);
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image.filePath.toLowerCase().endsWith('.pdf')
                        ? const Center(
                            child: Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
                          )
                        : Hero(
                            tag: 'image_${image.id}',
                            child: Image.file(
                              File(image.filePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                    if (image.isFavorite)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(Icons.star, color: Colors.amber, size: 24),
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
    );
  }

  void _showDeletedOptions(BuildContext context, ScannedImage image, ScannerProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إجراءات المستند المحذوف'),
        actions: [
          TextButton(
            onPressed: () {
              provider.restoreImage(image.id!);
              Navigator.pop(context);
            },
            child: const Text('استعادة'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteImagePermanently(image.id!);
              Navigator.pop(context);
            },
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}