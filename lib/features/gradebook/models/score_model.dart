class ScoreModel {
  final int? id;
  final int studentId;
  final int assignmentId;
  final double pointsEarned;

  ScoreModel({
    this.id,
    required this.studentId,
    required this.assignmentId,
    required this.pointsEarned,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'assignment_id': assignmentId,
      'points_earned': pointsEarned,
    };
  }

  factory ScoreModel.fromMap(Map<String, dynamic> map) {
    return ScoreModel(
      id: map['id'] != null ? map['id'] as int : null,
      studentId: map['student_id'] as int,
      assignmentId: map['assignment_id'] as int,
      pointsEarned: (map['points_earned'] as num).toDouble(),
    );
  }

  ScoreModel copyWith({
    int? id,
    int? studentId,
    int? assignmentId,
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
