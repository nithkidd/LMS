class ScoreModel {
  final String? id;
  final String studentId;
  final String assignmentId;
  final double pointsEarned;

  ScoreModel({
    this.id,
    required this.studentId,
    required this.assignmentId,
    required this.pointsEarned,
  });

  Map<String, dynamic> toDto() {
    return {
      'student_id': studentId,
      'assignment_id': assignmentId,
      'points_earned': pointsEarned,
    };
  }

  factory ScoreModel.fromDto(Map<dynamic, dynamic> map, String id) {
    return ScoreModel(
      id: id,
      studentId: map['student_id']?.toString() ?? '',
      assignmentId: map['assignment_id']?.toString() ?? '',
      pointsEarned: map['points_earned'] is num
          ? (map['points_earned'] as num).toDouble()
          : double.tryParse(map['points_earned']?.toString() ?? '0') ?? 0.0,
    );
  }

  ScoreModel copyWith({
    String? id,
    String? studentId,
    String? assignmentId,
    double? pointsEarned,
  }) {
    return ScoreModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      assignmentId: assignmentId ?? this.assignmentId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }
}
