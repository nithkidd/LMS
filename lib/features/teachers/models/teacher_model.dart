class TeacherModel {
  final String? id;
  final String schoolId;
  final String name;
  final String? createdAt;

  TeacherModel({
    this.id,
    required this.schoolId,
    required this.name,
    this.createdAt,
  });

  Map<String, dynamic> toDto() {
    return {'school_id': schoolId, 'name': name, 'created_at': createdAt};
  }

  factory TeacherModel.fromDto(Map<dynamic, dynamic> map, String id) {
    return TeacherModel(
      id: id,
      schoolId: map['school_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      createdAt: map['created_at']?.toString(),
    );
  }

  TeacherModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? createdAt,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schoolId == other.schoolId &&
          name == other.name;

  @override
  int get hashCode => id?.hashCode ?? 0 ^ schoolId.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'TeacherModel(id: $id, schoolId: $schoolId, name: $name)';
}
