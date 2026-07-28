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
  List<ScannedImage> get images => _images;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadImages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _images = await repository.getAllImages();
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
        _images.insert(0, newImage);
        _errorMessage = null;
        notifyListeners();
      } else {
        _errorMessage = 'لم يتم اختيار صورة';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'تعذر التقاط الصورة. تأكد من منح صلاحية الكاميرا/المعرض.';
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
        _images.insert(0, newImage);
        _errorMessage = null;
        notifyListeners();
      } else {
        _errorMessage = 'لم يتم اختيار ملف';
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
    final image = _images[index];
    if (image.id != null) {
      await repository.renameImage(image.id!, newTitle);
      _images[index] = image.copyWith(title: newTitle);
      notifyListeners();
    }
  }

  Future<void> deleteImage(int index) async {
    final image = _images[index];
    if (image.id != null) {
      await repository.deleteImage(image.id!);
      final file = File(image.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _images.removeAt(index);
      notifyListeners();
    }
  }
}