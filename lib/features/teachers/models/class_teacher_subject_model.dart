import '../../teachers/models/teacher_model.dart';
import '../../subjects/models/subject_model.dart';

class ClassTeacherSubjectModel {
  final String? id;
  final String classId;
  final String teacherId;
  final String subjectId;

  ClassTeacherSubjectModel({
    this.id,
    required this.classId,
    required this.teacherId,
    required this.subjectId,
  });

  Map<String, dynamic> toDto() {
    return {
      'class_id': classId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
    };
  }

  factory ClassTeacherSubjectModel.fromDto(
    Map<dynamic, dynamic> map,
    String id,
  ) {
    return ClassTeacherSubjectModel(
      id: id,
      classId: map['class_id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
    );
  }

  ClassTeacherSubjectModel copyWith({
    String? id,
    String? classId,
    String? teacherId,
    String? subjectId,
  }) {
    return ClassTeacherSubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  @override
  String toString() =>
      'ClassTeacherSubjectModel(id: $id, classId: $classId, teacherId: $teacherId, subjectId: $subjectId)';
}

// DTO for displaying with teacher and subject details
class ClassTeacherSubjectRow {
  final TeacherModel teacher;
  final SubjectModel subject;
  final String assignmentId;

  ClassTeacherSubjectRow({
    required this.teacher,
    required this.subject,
    required this.assignmentId,
  });
}
