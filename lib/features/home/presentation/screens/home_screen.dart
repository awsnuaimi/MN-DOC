import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../features/scanner/logic/scanner_provider.dart';
import '../../../../features/scanner/data/models/scanned_image.dart';
import '../../../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
    if (!File(image.filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ملف المستند غير موجود')),
      );
      return;
    }
    context.push('/editor', extra: image.filePath);
  }

  void _showOptionsDialog(
      BuildContext context, ScannedImage image, ScannerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionItem(Icons.edit_rounded, 'إعادة تسمية', () {
              Navigator.pop(context);
              _showRenameDialog(context, image, provider);
            }),
            _buildOptionItem(
              image.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              image.isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              () {
                Navigator.pop(context);
                provider.toggleFavorite(image.id!);
              },
              color: Colors.amber,
            ),
            _buildOptionItem(Icons.share_rounded, 'مشاركة', () {
              Navigator.pop(context);
              if (File(image.filePath).existsSync()) {
                Share.shareXFiles([XFile(image.filePath)],
                    text: 'مستند من MN Doc');
              }
            }),
            _buildOptionItem(Icons.delete_outline_rounded, 'حذف', () {
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
            }, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showRenameDialog(
      BuildContext context, ScannedImage image, ScannerProvider provider) {
    final controller = TextEditingController(text: image.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إعادة تسمية'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameImage(provider.images.indexOf(image),
                    controller.text.trim());
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
      body: Column(
        children: [
          // شريط علوي زجاجي
          _buildHeader(),
          // تبويبات دائرية
          _buildTabBar(),
          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsList(filter: 'all'),
                _buildDocumentsList(filter: 'favorites'),
                _buildDocumentsList(filter: 'deleted'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/scanner'),
        child: const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ScannerProvider>(
      builder: (context, provider, child) {
        final counts = [
          provider.images.length,
          provider.favoriteImages.length,
          provider.deletedImages.length,
        ];
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'مستنداتي',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded,
                        color: Colors.white),
                    onPressed: () {
                      // TODO: implement search
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // بطاقات الإحصائيات
              Row(
                children: [
                  _buildStatCard('الكل', counts[0], Icons.folder_rounded),
                  const SizedBox(width: 12),
                  _buildStatCard('المفضلة', counts[1], Icons.star_rounded),
                  const SizedBox(width: 12),
                  _buildStatCard('المهملات', counts[2], Icons.delete_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.gradientPrimary),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'المفضلة'),
            Tab(text: 'المهملات'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList({required String filter}) {
    return Consumer<ScannerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
                Icon(
                  filter == 'favorites'
                      ? Icons.star_outline_rounded
                      : filter == 'deleted'
                          ? Icons.delete_outline_rounded
                          : Icons.description_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مستندات',
                  style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final image = documents[index];
              return _buildDocumentCard(image, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(ScannedImage image, ScannerProvider provider) {
    return GestureDetector(
      onTap: () => _openDocument(image, provider),
      onLongPress: () => _showOptionsDialog(context, image, provider),
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
              // صورة المستند
              image.filePath.toLowerCase().endsWith('.pdf')
                  ? Center(
                      child: Icon(Icons.picture_as_pdf_rounded,
                          size: 48, color: Colors.red[300]),
                    )
                  : Image.file(File(image.filePath), fit: BoxFit.cover),
              // تأثير زجاجي فوق الصورة
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // نجمة المفضلة
              if (image.isFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              // عنوان المستند
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Text(
                  image.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}