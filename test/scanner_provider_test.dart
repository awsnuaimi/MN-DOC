import 'package:flutter_test/flutter_test.dart';
import 'package:mn_doc/features/scanner/data/models/scanned_image.dart';
import 'package:mn_doc/features/scanner/data/repositories/scanner_repository.dart';
import 'package:mn_doc/features/scanner/logic/scanner_provider.dart';
import 'package:mn_doc/core/services/local_db.dart';

/// مستودع وهمي في الذاكرة، يحاكي جدول scanned_images بدون الحاجة لـ sqflite حقيقية.
class FakeScannerRepository extends ScannerRepository {
  final List<ScannedImage> _store = [];
  int _nextId = 1;

  FakeScannerRepository() : super(localDB: LocalDB());

  @override
  Future<List<ScannedImage>> getAllImages({bool includeDeleted = false}) async {
    return _store.where((e) => includeDeleted || !e.isDeleted).toList();
  }

  @override
  Future<List<ScannedImage>> getFavoriteImages() async =>
      _store.where((e) => e.isFavorite && !e.isDeleted).toList();

  @override
  Future<List<ScannedImage>> getDeletedImages() async =>
      _store.where((e) => e.isDeleted).toList();

  @override
  Future<void> saveImage(ScannedImage image) async {
    _store.add(image.copyWith(id: _nextId++));
  }

  @override
  Future<void> updateImage(ScannedImage image) async {
    final i = _store.indexWhere((e) => e.id == image.id);
    if (i != -1) _store[i] = image;
  }

  @override
  Future<void> renameImage(int id, String newTitle) async {
    final i = _store.indexWhere((e) => e.id == id);
    if (i != -1) _store[i] = _store[i].copyWith(title: newTitle);
  }

  @override
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final i = _store.indexWhere((e) => e.id == id);
    if (i != -1) _store[i] = _store[i].copyWith(isFavorite: isFavorite);
  }

  @override
  Future<void> softDeleteImage(int id) async {
    final i = _store.indexWhere((e) => e.id == id);
    if (i != -1) _store[i] = _store[i].copyWith(isDeleted: true);
  }

  @override
  Future<void> restoreImage(int id) async {
    final i = _store.indexWhere((e) => e.id == id);
    if (i != -1) _store[i] = _store[i].copyWith(isDeleted: false);
  }

  @override
  Future<void> deleteImagePermanently(int id) async {
    _store.removeWhere((e) => e.id == id);
  }
}

void main() {
  late FakeScannerRepository repo;
  late ScannerProvider provider;

  setUp(() {
    repo = FakeScannerRepository();
    provider = ScannerProvider(repository: repo);
  });

  test('تحميل الصور يعبّئ اللائحة الأساسية', () async {
    await repo.saveImage(ScannedImage(filePath: 'a.jpg', title: 'مستند 1'));
    await provider.loadImages();
    expect(provider.images.length, 1);
  });

  test(
      'باج سابق: العنصر المحذوف يجب أن يبقى ظاهراً في سلة المهملات '
      'حتى بعد إعادة تحميل القائمة (محاكاة إعادة تشغيل التطبيق)', () async {
    await repo.saveImage(ScannedImage(filePath: 'a.jpg', title: 'مستند 1'));
    await provider.loadImages();
    final id = provider.images.first.id!;

    await provider.softDeleteImage(id);
    expect(provider.deletedImages.length, 1, reason: 'يجب أن يظهر فوراً بعد الحذف');

    // محاكاة إعادة تشغيل التطبيق: نعمل provider جديد يقرأ من نفس المستودع
    final freshProvider = ScannerProvider(repository: repo);
    await freshProvider.loadImages();
    expect(freshProvider.deletedImages.length, 1,
        reason: 'يجب أن يبقى ظاهراً بسلة المهملات بعد إعادة التحميل، لا يختفي');
    expect(freshProvider.images.length, 0, reason: 'ولا يظهر ضمن قائمة الكل');
  });

  test('استعادة عنصر من المهملات يرجّعه للقائمة الأساسية', () async {
    await repo.saveImage(ScannedImage(filePath: 'a.jpg', title: 'مستند 1'));
    await provider.loadImages();
    final id = provider.images.first.id!;

    await provider.softDeleteImage(id);
    await provider.restoreImage(id);

    expect(provider.images.length, 1);
    expect(provider.deletedImages.length, 0);
  });

  test('تبديل المفضلة يعمل ويظهر بلائحة المفضلة', () async {
    await repo.saveImage(ScannedImage(filePath: 'a.jpg', title: 'مستند 1'));
    await provider.loadImages();
    final id = provider.images.first.id!;

    await provider.toggleFavorite(id);
    expect(provider.favoriteImages.length, 1);

    await provider.toggleFavorite(id);
    expect(provider.favoriteImages.length, 0);
  });
}