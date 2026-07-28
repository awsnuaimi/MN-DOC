import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../data/models/scanned_image.dart';
import '../data/repositories/scanner_repository.dart';

class ScannerProvider extends ChangeNotifier {
  final ScannerRepository repository;
  final ImagePicker _picker = ImagePicker();

  ScannerProvider({required this.repository});

  List<ScannedImage> _images = [];
  List<ScannedImage> get images => _images.where((img) => !img.isDeleted).toList();

  List<ScannedImage> get favoriteImages =>
      _images.where((img) => img.isFavorite && !img.isDeleted).toList();

  List<ScannedImage> get deletedImages =>
      _images.where((img) => img.isDeleted).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // تحميل الكل بما فيهم المحذوفات لتظهر في سلة المهملات
      _images = await repository.getAllImages(includeDeleted: true);
    } catch (e) {
      _errorMessage = 'فشل تحميل الصور';
    }
    _isLoading = false;
    notifyListeners();
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
        // إعادة تحميل القائمة للحصول على id صحيح
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
}