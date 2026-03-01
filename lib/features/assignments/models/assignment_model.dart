class AssignmentModel {
  final int? id;
  final int classId;
  final String name;
  final String month;
  final String year;
  final double maxPoints;

  AssignmentModel({
    this.id,
    required this.classId,
    required this.name,
    required this.month,
    required this.year,
    required this.maxPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'month': month,
      'year': year,
      'max_points': maxPoints,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] != null ? map['id'] as int : null,
      classId: map['class_id'] as int,
      name: map['name'] ?? '',
      month: map['month'] ?? '',
      year: map['year'] ?? '',
      maxPoints: (map['max_points'] as num).toDouble(),
    );
  }

  AssignmentModel copyWith({
    int? id,
    int? classId,
    String? name,
    String? month,
    String? year,
    double? maxPoints,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      month: month ?? this.month,
      year: year ?? this.year,
      maxPoints: maxPoints ?? this.maxPoints,
    );
  }
}
