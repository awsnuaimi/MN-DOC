import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> loadImages() async {
    _isLoading = true;
    notifyListeners();
    _images = await repository.getAllImages();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
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
      notifyListeners();
    }
  }

  Future<void> updateImage(ScannedImage updatedImage) async {
    await repository.updateImage(updatedImage);
    final index = _images.indexWhere((img) => img.id == updatedImage.id);
    if (index != -1) {
      _images[index] = updatedImage;
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