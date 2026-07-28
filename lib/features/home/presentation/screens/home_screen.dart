import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

  void _openDocument(ScannedImage image) {
    if (!File(image.filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ملف المستند غير موجود')));
      return;
    }
    context.push('/editor', extra: image.filePath);
  }

  void _showOptionsDialog(BuildContext context, ScannedImage image, ScannerProvider provider) {
    final isFavorite = image.isFavorite;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber),
              title: Text(isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleFavorite(image.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('إعادة تسمية'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, image, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(context);
                if (File(image.filePath).existsSync()) {
                  Share.shareXFiles([XFile(image.filePath)], text: 'مستند من MN Doc');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                provider.softDeleteImage(image.id!);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('تم نقل المستند إلى سلة المهملات'),
                  action: SnackBarAction(label: 'تراجع', onPressed: () => provider.restoreImage(image.id!)),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  // خيارات خاصة بعنصر بسلة المهملات — استعادة أو حذف نهائي
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

  void _showRenameDialog(BuildContext context, ScannedImage image, ScannerProvider provider) {
    final controller = TextEditingController(text: image.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إعادة تسمية المستند'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
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
        title: const Text('مستنداتي'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'الكل'),
            Tab(icon: Icon(Icons.star_rounded), text: 'المفضلة'),
            Tab(icon: Icon(Icons.delete_outline_rounded), text: 'المهملات'),
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
    );
  }

  Widget _buildDocumentsList({required String filter}) {
    return Consumer<ScannerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

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
                Icon(
                  filter == 'favorites'
                      ? Icons.star_outline_rounded
                      : filter == 'deleted'
                          ? Icons.delete_outline_rounded
                          : Icons.description_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
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
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: documents.length,
          itemBuilder: (context, index) => _buildDocumentCard(documents[index], provider),
        );
      },
    );
  }

  Widget _buildDocumentCard(ScannedImage image, ScannerProvider provider) {
    return GestureDetector(
      onTap: () => image.isDeleted ? _showDeletedOptions(context, image, provider) : _openDocument(image),
      onLongPress: () => image.isDeleted ? null : _showOptionsDialog(context, image, provider),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image.filePath.toLowerCase().endsWith('.pdf')
                ? Center(child: Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.red[300]))
                : Image.file(File(image.filePath), fit: BoxFit.cover),
            if (image.isFavorite)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(image.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}