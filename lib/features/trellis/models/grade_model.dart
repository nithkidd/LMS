import 'firestore_value_parser.dart';

class GradeModel {
  final String? id;
  final String assessmentId;
  final String studentId;
  final String classId;
  final double score;
  final bool isExcused;

  const GradeModel({
    this.id,
    required this.assessmentId,
    required this.studentId,
    required this.classId,
    required this.score,
    this.isExcused = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'assessmentId': assessmentId,
      'studentId': studentId,
      'classId': classId,
      'score': score,
      'isExcused': isExcused,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory GradeModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return GradeModel(
      id: documentId ?? readNullableString(map['id']),
      assessmentId: readString(map['assessmentId']),
      studentId: readString(map['studentId']),
      classId: readString(map['classId']),
      score: readDouble(map['score']),
      isExcused: readBool(map['isExcused']),
    );
  }

  GradeModel copyWith({
    String? id,
    String? assessmentId,
    String? studentId,
    String? classId,
    double? score,
    bool? isExcused,
  }) {
    return GradeModel(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      score: score ?? this.score,
      isExcused: isExcused ?? this.isExcused,
    );
  }

  static String buildDocumentId({
    required String assessmentId,
    required String studentId,
  }) {
    return '${assessmentId}_$studentId';
  }
}
