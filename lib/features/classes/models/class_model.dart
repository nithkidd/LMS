class ClassModel {
  final int? id;
  final int schoolId;
  final String name;
  final String academicYear;
  final bool isAdviser;

  ClassModel({
    this.id,
    required this.schoolId,
    required this.name,
    required this.academicYear,
    this.isAdviser = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'academic_year': academicYear,
      'is_adviser': isAdviser ? 1 : 0,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] != null ? map['id'] as int : null,
      schoolId: map['school_id'] as int,
      name: map['name'] ?? '',
      academicYear: map['academic_year'] ?? '',
      isAdviser: map['is_adviser'] == 1,
    );
  }

  ClassModel copyWith({
    int? id,
    int? schoolId,
    String? name,
    String? academicYear,
    bool? isAdviser,
  }) {
    return ClassModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      academicYear: academicYear ?? this.academicYear,
      isAdviser: isAdviser ?? this.isAdviser,
    );
  }
}
