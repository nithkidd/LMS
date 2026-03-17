class SchoolModel {
  final String? id;
  final String name;
  final String? createdAt;
  final int displayOrder;

  SchoolModel({
    this.id,
    required this.name,
    this.createdAt,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toDto() {
    return {
      'name': name,
      'created_at': createdAt,
      'display_order': displayOrder,
    };
  }

  factory SchoolModel.fromDto(Map<dynamic, dynamic> map, String id) {
    final rawDisplayOrder = map['display_order'];
    return SchoolModel(
      id: id,
      name: map['name']?.toString() ?? '',
      createdAt: map['created_at']?.toString(),
      displayOrder: rawDisplayOrder is int
          ? rawDisplayOrder
          : int.tryParse(rawDisplayOrder?.toString() ?? '') ?? 0,
    );
  }

  SchoolModel copyWith({
    String? id,
    String? name,
    String? createdAt,
    int? displayOrder,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
