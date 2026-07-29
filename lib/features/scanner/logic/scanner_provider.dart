import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'dart:io';
import '../data/models/scanned_image.dart';
import '../data/repositories/scanner_repository.dart';

class ScannerProvider extends ChangeNotifier {
  final ScannerRepository repository;
  final ImagePicker _picker = ImagePicker();

  ScannerProvider({required this.repository});

  List<ScannedImage> _images = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<ScannedImage> _applySearch(List<ScannedImage> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((img) => img.title.toLowerCase().contains(q)).toList();
  }

  List<ScannedImage> get images =>
      _applySearch(_images.where((img) => !img.isDeleted).toList());

  List<ScannedImage> get favoriteImages =>
      _applySearch(_images.where((img) => img.isFavorite && !img.isDeleted).toList());

  List<ScannedImage> get pinnedImages =>
      _images.where((img) => img.isPinned && !img.isDeleted).toList();

  List<ScannedImage> get deletedImages =>
      _images.where((img) => img.isDeleted).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _images = await repository.getAllImages(includeDeleted: true);
    } catch (e) {
      _errorMessage = 'فشل تحميل الصور';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// مسح ذكي عبر Google ML Kit Document Scanner API — كشف حواف تلقائي،
  /// تصحيح منظور، وإمكانية مسح عدة صفحات بجلسة وحدة. مجاني وعلى الجهاز بالكامل.
  Future<void> scanWithDocScanner({int maxPages = 5}) async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dynamic result =
          await FlutterDocScanner().getScannedDocumentAsImages(page: maxPages);

      final List<String> uris = _extractImageUris(result);
      if (uris.isEmpty) {
        _errorMessage = 'لم يتم إتمام المسح';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        for (var i = 0; i < uris.length; i++) {
          final sourceFile = _resolveFileFromUri(uris[i]);
          if (sourceFile == null || !await sourceFile.exists()) continue;
          final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final savedImage = File('${appDir.path}/$fileName');
          await sourceFile.copy(savedImage.path);
          await repository.saveImage(
            ScannedImage(filePath: savedImage.path, title: 'مسح ${_images.length + i + 1}'),
          );
        }
        await loadImages();
      }
    } catch (e) {
      _errorMessage = 'تعذر إتمام المسح الذكي. جرّب الكاميرا العادية بدلاً منه.';
    }
    _isScanning = false;
    notifyListeners();
  }

  List<String> _extractImageUris(dynamic result) {
    if (result is Map) {
      final imgs = result['images'] ?? result['Uri'];
      if (imgs is List) return imgs.map((e) => e.toString()).toList();
      if (imgs is String) return [imgs];
    }
    if (result is String) return [result];
    return [];
  }

  /// نتائج الحزمة قد تُرجع مسار ملف مباشر أو URI بصيغة file:// — نتعامل مع
  /// الحالتين دفاعياً بدل الافتراض المسبق لصيغة واحدة.
  File? _resolveFileFromUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme == 'file') return File(uri.toFilePath());
      if (uri.scheme.isEmpty) return File(uriString);
      return File(uriString);
    } catch (_) {
      return File(uriString);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');
        await File(picked.path).copy(savedImage.path);

        final newImage = ScannedImage(
          filePath: savedImage.path,
          title: 'مسح ${_images.length + 1}',
        );
        await repository.saveImage(newImage);
        await loadImages();
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'تعذر التقاط الصورة. تأكد من صلاحية الكاميرا.';
      notifyListeners();
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final extension = result.files.single.extension ?? 'jpg';
        final fileName = 'file_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final savedFile = File('${appDir.path}/$fileName');
        await pickedFile.copy(savedFile.path);

        final newImage = ScannedImage(
          filePath: savedFile.path,
          title: result.files.single.name,
        );
        await repository.saveImage(newImage);
        await loadImages();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'تعذر استيراد الملف.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateImage(ScannedImage updatedImage) async {
    await repository.updateImage(updatedImage);
    final index = _images.indexWhere((img) => img.id == updatedImage.id);
    if (index != -1) {
      _images[index] = updatedImage;
      notifyListeners();
    }
  }

  Future<void> renameImage(int index, String newTitle) async {
    final image = images[index];
    if (image.id != null) {
      await repository.renameImage(image.id!, newTitle);
      final realIndex = _images.indexWhere((img) => img.id == image.id);
      if (realIndex != -1) {
        _images[realIndex] = image.copyWith(title: newTitle);
        notifyListeners();
      }
    }
  }

  Future<void> toggleFavorite(int id) async {
    final index = _images.indexWhere((img) => img.id == id);
    if (index != -1) {
      final newState = !_images[index].isFavorite;
      await repository.toggleFavorite(id, newState);
      _images[index] = _images[index].copyWith(isFavorite: newState);
      notifyListeners();
    }
  }

  Future<void> togglePin(int id) async {
    final index = _images.indexWhere((img) => img.id == id);
    if (index != -1) {
      final newState = !_images[index].isPinned;
      await repository.togglePin(id, newState);
      _images[index] = _images[index].copyWith(isPinned: newState);
      notifyListeners();
    }
  }

  Future<void> softDeleteImage(int id) async {
    final index = _images.indexWhere((img) => img.id == id);
    if (index != -1) {
      await repository.softDeleteImage(id);
      _images[index] = _images[index].copyWith(isDeleted: true);
      notifyListeners();
    }
  }

  Future<void> restoreImage(int id) async {
    final index = _images.indexWhere((img) => img.id == id);
    if (index != -1) {
      await repository.restoreImage(id);
      _images[index] = _images[index].copyWith(isDeleted: false);
      notifyListeners();
    }
  }

  Future<void> deleteImagePermanently(int id) async {
    final index = _images.indexWhere((img) => img.id == id);
    if (index != -1) {
      await repository.deleteImagePermanently(id);
      final file = File(_images[index].filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _images.removeAt(index);
      notifyListeners();
    }
  }

  Future<double> calculateUsedStorageMB() async {
    int totalBytes = 0;
    for (final image in _images) {
      final file = File(image.filePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }
}