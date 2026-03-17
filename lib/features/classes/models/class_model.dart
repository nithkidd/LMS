class ClassModel {
  final String? id;
  final String schoolId;
  final String name;
  final String academicYear;
  final bool isAdviser;
  final int totalStudents;
  final int femaleStudents;

  ClassModel({
    this.id,
    required this.schoolId,
    required this.name,
    required this.academicYear,
    this.isAdviser = false,
    this.totalStudents = 0,
    this.femaleStudents = 0,
  });

  Map<String, dynamic> toDto() {
    return {
      'school_id': schoolId,
      'name': name,
      'academic_year': academicYear,
      'is_adviser': isAdviser,
    };
  }

  factory ClassModel.fromDto(Map<dynamic, dynamic> map, String id) {
    return ClassModel(
      id: id,
      schoolId: map['school_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      academicYear: map['academic_year']?.toString() ?? '',
      isAdviser:
          map['is_adviser'] == true ||
          map['is_adviser'] == 1 ||
          map['is_adviser'] == 'true',
      totalStudents: map['total_students'] is int
          ? map['total_students'] as int
          : int.tryParse(map['total_students']?.toString() ?? '') ?? 0,
      femaleStudents: map['female_students'] is int
          ? map['female_students'] as int
          : int.tryParse(map['female_students']?.toString() ?? '') ?? 0,
    );
  }

  ClassModel copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? academicYear,
    bool? isAdviser,
    int? totalStudents,
    int? femaleStudents,
  }) {
    return ClassModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      academicYear: academicYear ?? this.academicYear,
      isAdviser: isAdviser ?? this.isAdviser,
      totalStudents: totalStudents ?? this.totalStudents,
      femaleStudents: femaleStudents ?? this.femaleStudents,
    );
  }
}
