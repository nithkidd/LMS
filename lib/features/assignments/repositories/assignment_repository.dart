import '../../../core/database/database_helper.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(AssignmentModel assignment) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      DatabaseHelper.tableAssignments,
      assignment.toDto(),
    );
    return id.toString();
  }

  Future<List<AssignmentModel>> getByClassId(String classId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableAssignments,
      where: 'class_id = ?',
      whereArgs: [classId],
    );

    final assignments = rows
        .map((row) => AssignmentModel.fromDto(row, row['id'].toString()))
        .toList();

    assignments.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return b.month.compareTo(a.month);
    });

    return assignments;
  }

  Future<AssignmentModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableAssignments,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AssignmentModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(AssignmentModel assignment) async {
    if (assignment.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableAssignments,
      assignment.toDto(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableAssignments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
