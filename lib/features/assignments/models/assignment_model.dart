class AssignmentModel {
  final String? id;
  final String classId;
  final String subjectId;
  final String name;
  final String month;
  final String year;
  final double maxPoints;

  AssignmentModel({
    this.id,
    required this.classId,
    required this.subjectId,
    required this.name,
    required this.month,
    required this.year,
    required this.maxPoints,
  });

  Map<String, dynamic> toDto() {
    return {
      'class_id': classId,
      'subject_id': subjectId,
      'name': name,
      'month': month,
      'year': year,
      'max_points': maxPoints,
    };
  }

  factory AssignmentModel.fromDto(Map<dynamic, dynamic> map, String id) {
    return AssignmentModel(
      id: id,
      classId: map['class_id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      month: map['month']?.toString() ?? '',
      year: map['year']?.toString() ?? '',
      maxPoints: map['max_points'] is num
          ? (map['max_points'] as num).toDouble()
          : double.tryParse(map['max_points']?.toString() ?? '0') ?? 0.0,
    );
  }

  AssignmentModel copyWith({
    String? id,
    String? classId,
    String? subjectId,
    String? name,
    String? month,
    String? year,
    double? maxPoints,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      month: month ?? this.month,
      year: year ?? this.year,
      maxPoints: maxPoints ?? this.maxPoints,
    );
  }
}
