import '../../../core/database/database_helper.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/teacher_model.dart';

class TeacherRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(TeacherModel teacher) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableTeachers, teacher.toDto());
    return id.toString();
  }

  Future<List<TeacherModel>> getTeachersBySchoolId(String schoolId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableTeachers,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );

    final teachers = rows
        .map((row) => TeacherModel.fromDto(row, row['id'].toString()))
        .toList();

    KhmerCollator.sortBy(teachers, (teacher) => teacher.name);
    return teachers;
  }

  Future<TeacherModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableTeachers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TeacherModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(TeacherModel teacher) async {
    if (teacher.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTeachers,
      teacher.toDto(),
      where: 'id = ?',
      whereArgs: [teacher.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTeachers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
