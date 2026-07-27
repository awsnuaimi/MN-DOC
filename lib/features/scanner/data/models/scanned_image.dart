class ScannedImage {
  final int? id;
  final String filePath;
  final String title;
  final DateTime createdAt;

  ScannedImage({
    this.id,
    required this.filePath,
    required this.title,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'filePath': filePath,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScannedImage.fromMap(Map<String, dynamic> map) => ScannedImage(
        id: map['id'],
        filePath: map['filePath'] ?? '',
        title: map['title'] ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
      );
}