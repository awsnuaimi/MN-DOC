class ScannedImage {
  final int? id;
  final String filePath;
  final String title;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isDeleted;

  ScannedImage({
    this.id,
    required this.filePath,
    required this.title,
    DateTime? createdAt,
    this.isFavorite = false,
    this.isDeleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'filePath': filePath,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite ? 1 : 0,
        'isDeleted': isDeleted ? 1 : 0,
      };

  factory ScannedImage.fromMap(Map<String, dynamic> map) => ScannedImage(
        id: map['id'],
        filePath: map['filePath'] ?? '',
        title: map['title'] ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        isFavorite: (map['isFavorite'] ?? 0) == 1,
        isDeleted: (map['isDeleted'] ?? 0) == 1,
      );

  ScannedImage copyWith({
    int? id,
    String? filePath,
    String? title,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isDeleted,
  }) =>
      ScannedImage(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        isFavorite: isFavorite ?? this.isFavorite,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}