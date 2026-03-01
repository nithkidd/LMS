import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(AssignmentModel assignment) async {
    Database db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableAssignments, assignment.toMap());
  }

  Future<List<AssignmentModel>> getByClassId(int classId) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAssignments,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'year DESC, month DESC',
    );
    return maps.map((map) => AssignmentModel.fromMap(map)).toList();
  }

  Future<AssignmentModel?> getById(int id) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAssignments,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return AssignmentModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(AssignmentModel assignment) async {
    Database db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableAssignments,
      assignment.toMap(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  Future<int> delete(int id) async {
    Database db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableAssignments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
