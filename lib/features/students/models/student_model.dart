class StudentModel {
  final int? id;
  final int classId;
  final String name;

  StudentModel({
    this.id,
    required this.classId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] != null ? map['id'] as int : null,
      classId: map['class_id'] as int,
      name: map['name'] ?? '',
    );
  }

  StudentModel copyWith({
    int? id,
    int? classId,
    String? name,
  }) {
    return StudentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
    );
  }
}
