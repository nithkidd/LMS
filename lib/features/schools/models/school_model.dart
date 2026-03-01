class SchoolModel {
  final int? id;
  final String name;

  SchoolModel({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory SchoolModel.fromMap(Map<String, dynamic> map) {
    return SchoolModel(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['name'] ?? '',
    );
  }

  SchoolModel copyWith({
    int? id,
    String? name,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
