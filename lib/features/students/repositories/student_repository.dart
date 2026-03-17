import '../../../core/database/database_helper.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/student_model.dart';

class StudentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(StudentModel student) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableStudents, student.toDto());
    return id.toString();
  }

  Future<List<StudentModel>> getStudentsByClassId(String classId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableStudents,
      where: 'class_id = ?',
      whereArgs: [classId],
    );

    final students = rows
        .map((row) => StudentModel.fromDto(row, row['id'].toString()))
        .toList();

    KhmerCollator.sortBy(students, (student) => student.name);
    return students;
  }

  Future<StudentModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableStudents,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StudentModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(StudentModel student) async {
    if (student.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableStudents,
      student.toDto(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableStudents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
