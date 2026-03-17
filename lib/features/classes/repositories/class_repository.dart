import '../../../core/database/database_helper.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/class_model.dart';

class ClassRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(ClassModel classModel) async {
    final db = await _dbHelper.database;
    final data = classModel.toDto()
      ..['is_adviser'] = classModel.isAdviser ? 1 : 0;
    final id = await db.insert(DatabaseHelper.tableClasses, data);
    return id.toString();
  }

  Future<List<ClassModel>> getClassesBySchoolId(String schoolId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.*,
        COUNT(s.id) AS total_students,
        SUM(CASE WHEN s.sex = 'F' THEN 1 ELSE 0 END) AS female_students
      FROM ${DatabaseHelper.tableClasses} c
      LEFT JOIN ${DatabaseHelper.tableStudents} s
        ON s.class_id = c.id
      WHERE c.school_id = ?
      GROUP BY c.id
      ''',
      [schoolId],
    );

    final classes = rows
        .map((row) => ClassModel.fromDto(row, row['id'].toString()))
        .toList();

    KhmerCollator.sortBy(classes, (classModel) => classModel.name);
    return classes;
  }

  Future<List<ClassModel>> getAllClasses() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        c.*,
        COUNT(s.id) AS total_students,
        SUM(CASE WHEN s.sex = 'F' THEN 1 ELSE 0 END) AS female_students
      FROM ${DatabaseHelper.tableClasses} c
      LEFT JOIN ${DatabaseHelper.tableStudents} s
        ON s.class_id = c.id
      GROUP BY c.id
    ''');

    final classes = rows
        .map((row) => ClassModel.fromDto(row, row['id'].toString()))
        .toList();

    KhmerCollator.sortBy(classes, (classModel) => classModel.name);
    return classes;
  }

  Future<ClassModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableClasses,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClassModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(ClassModel classModel) async {
    if (classModel.id == null) return;

    final db = await _dbHelper.database;
    final data = classModel.toDto()
      ..['is_adviser'] = classModel.isAdviser ? 1 : 0;
    await db.update(
      DatabaseHelper.tableClasses,
      data,
      where: 'id = ?',
      whereArgs: [classModel.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableClasses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
