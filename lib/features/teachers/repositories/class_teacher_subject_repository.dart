import '../../../core/database/database_helper.dart';
import '../../subjects/models/subject_model.dart';
import '../../teachers/models/teacher_model.dart';
import '../models/class_teacher_subject_model.dart';

class ClassTeacherSubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(ClassTeacherSubjectModel model) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      DatabaseHelper.tableClassTeacherSubject,
      model.toDto(),
    );
    return id.toString();
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableClassTeacherSubject,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByClassAndTeacherAndSubject({
    required String classId,
    required String teacherId,
    required String subjectId,
  }) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableClassTeacherSubject,
      where: 'class_id = ? AND teacher_id = ? AND subject_id = ?',
      whereArgs: [classId, teacherId, subjectId],
    );
  }

  Future<List<ClassTeacherSubjectModel>> getByClassAndTeacher({
    required String classId,
    required String teacherId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableClassTeacherSubject,
      where: 'class_id = ? AND teacher_id = ?',
      whereArgs: [classId, teacherId],
    );

    return rows
        .map(
          (row) => ClassTeacherSubjectModel.fromDto(row, row['id'].toString()),
        )
        .toList();
  }

  Future<List<String>> getAssignedSubjectIds({
    required String classId,
    required String teacherId,
  }) async {
    final assignments = await getByClassAndTeacher(
      classId: classId,
      teacherId: teacherId,
    );
    return assignments.map((assignment) => assignment.subjectId).toList();
  }

  Future<List<ClassTeacherSubjectRow>> getTeachersByClassAndSubject({
    required String classId,
    required String subjectId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        cts.id AS assignment_id,
        t.id AS teacher_id,
        t.school_id,
        t.name AS teacher_name,
        t.created_at AS teacher_created_at,
        s.id AS subject_id,
        s.class_id AS subject_class_id,
        s.name AS subject_name,
        s.display_order
      FROM ${DatabaseHelper.tableClassTeacherSubject} cts
      INNER JOIN ${DatabaseHelper.tableTeachers} t ON t.id = cts.teacher_id
      INNER JOIN ${DatabaseHelper.tableSubjects} s ON s.id = cts.subject_id
      WHERE cts.class_id = ? AND cts.subject_id = ?
      ''',
      [classId, subjectId],
    );

    return rows.map(_mapRowToAssignment).toList();
  }

  Future<List<ClassTeacherSubjectRow>> getSubjectsWithTeachers({
    required String classId,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        cts.id AS assignment_id,
        t.id AS teacher_id,
        t.school_id,
        t.name AS teacher_name,
        t.created_at AS teacher_created_at,
        s.id AS subject_id,
        s.class_id AS subject_class_id,
        s.name AS subject_name,
        s.display_order
      FROM ${DatabaseHelper.tableClassTeacherSubject} cts
      INNER JOIN ${DatabaseHelper.tableTeachers} t ON t.id = cts.teacher_id
      INNER JOIN ${DatabaseHelper.tableSubjects} s ON s.id = cts.subject_id
      WHERE cts.class_id = ?
      ''',
      [classId],
    );

    final assignments = rows.map(_mapRowToAssignment).toList();
    assignments.sort((a, b) {
      final subjectCompare = a.subject.name.compareTo(b.subject.name);
      if (subjectCompare != 0) return subjectCompare;
      return a.teacher.name.compareTo(b.teacher.name);
    });
    return assignments;
  }

  ClassTeacherSubjectRow _mapRowToAssignment(Map<String, Object?> row) {
    final displayOrder = row['display_order'];
    return ClassTeacherSubjectRow(
      teacher: TeacherModel(
        id: row['teacher_id'].toString(),
        schoolId: row['school_id'].toString(),
        name: row['teacher_name']?.toString() ?? '',
        createdAt: row['teacher_created_at']?.toString(),
      ),
      subject: SubjectModel(
        id: row['subject_id'].toString(),
        classId: row['subject_class_id'].toString(),
        name: row['subject_name']?.toString() ?? '',
        displayOrder: displayOrder == null
            ? null
            : int.tryParse(displayOrder.toString()),
      ),
      assignmentId: row['assignment_id'].toString(),
    );
  }
}
