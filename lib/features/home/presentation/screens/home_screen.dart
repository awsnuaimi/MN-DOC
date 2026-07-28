import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../features/scanner/logic/scanner_provider.dart';
import '../../../../features/scanner/data/models/scanned_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

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
              leading: Icon(isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber),
              title: Text(isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleFavorite(image.id!);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('إعادة تسمية'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, image, provider);
              },
            ),
            ListTile(
              leading: Icon(Icons.share_rounded, color: Theme.of(context).colorScheme.primary),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
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
      body: Column(
        children: [
          const _StatsStrip(),
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
          final onSurface = Theme.of(context).colorScheme.onSurface;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    filter == 'favorites'
                        ? Icons.star_outline_rounded
                        : filter == 'deleted'
                            ? Icons.delete_outline_rounded
                            : Icons.description_outlined,
                    size: 40,
                    color: onSurface.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  filter == 'favorites'
                      ? 'لا توجد مفضلات'
                      : filter == 'deleted'
                          ? 'سلة المهملات فارغة'
                          : 'لا توجد مستندات بعد',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurface.withOpacity(0.7)),
                ),
                if (filter == 'all') ...[
                  const SizedBox(height: 6),
                  Text('اضغط على زر + بالأسفل لمسح أول مستند',
                      style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.4))),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82),
          itemCount: documents.length,
          itemBuilder: (context, index) =>
              _AnimatedIn(index: index, child: _buildDocumentCard(documents[index], provider)),
        );
      },
    );
  }

  Widget _buildDocumentCard(ScannedImage image, ScannerProvider provider) {
    return GestureDetector(
      onTap: () => image.isDeleted ? _showDeletedOptions(context, image, provider) : _openDocument(image),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image.filePath.toLowerCase().endsWith('.pdf')
                ? Container(
                    color: AppColors.lightWash,
                    child: Center(child: Icon(Icons.picture_as_pdf_rounded, size: 44, color: Colors.red[300])),
                  )
                : Image.file(File(image.filePath), fit: BoxFit.cover),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 72,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ),

            if (image.isFavorite)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                ),
              ),

            if (!image.isDeleted)
              Positioned(
                top: 4,
                left: 4,
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showOptionsDialog(context, image, provider),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.more_vert_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(image.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(DateFormatter.timeAgo(image.createdAt),
                      style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط إحصائيات صغير أعلى الشاشة الرئيسية.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Consumer<ScannerProvider>(
      builder: (context, provider, child) {
        final total = provider.images.length;
        final favorites = provider.favoriteImages.length;
        final thisWeek = provider.images
            .where((img) => DateTime.now().difference(img.createdAt).inDays < 7)
            .length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(child: _StatChip(icon: Icons.description_rounded, value: '$total', label: 'الكل')),
              const SizedBox(width: 10),
              Expanded(child: _StatChip(icon: Icons.star_rounded, value: '$favorites', label: 'مفضلة')),
              const SizedBox(width: 10),
              Expanded(child: _StatChip(icon: Icons.trending_up_rounded, value: '$thisWeek', label: 'هالأسبوع')),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.primary)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
        ],
      ),
    );
  }
}

/// حركة دخول تدرّجية للبطاقات (fade + slide) بدل الظهور الفوري الجامد.
class _AnimatedIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedIn({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index % 8) * 45),
      curve: Curves.easeOutCubic,
      builder: (context, value, cachedChild) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: cachedChild),
      ),
      child: child,
    );
  }
}