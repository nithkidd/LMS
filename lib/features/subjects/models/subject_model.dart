class SubjectModel {
  final String? id;
  final String classId;
  final String name;
  final int? displayOrder;

  SubjectModel({
    this.id,
    required this.classId,
    required this.name,
    this.displayOrder,
  });

  Map<String, dynamic> toDto() {
    return {'class_id': classId, 'name': name, 'display_order': displayOrder};
  }

  factory SubjectModel.fromDto(Map<dynamic, dynamic> map, String id) {
    final rawDisplayOrder = map['display_order'];
    return SubjectModel(
      id: id,
      classId: map['class_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      displayOrder: rawDisplayOrder is int
          ? rawDisplayOrder
          : int.tryParse(rawDisplayOrder?.toString() ?? ''),
    );
  }

  SubjectModel copyWith({
    String? id,
    String? classId,
    String? name,
    int? displayOrder,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
