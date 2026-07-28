class Profile {
  final int? id;
  final String name;
  final String email;
  final String phone;

  Profile({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'],
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
      );

  Profile copyWith({int? id, String? name, String? email, String? phone}) => Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );
}