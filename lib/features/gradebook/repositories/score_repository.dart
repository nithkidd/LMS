import '../../../core/database/database_helper.dart';
import '../models/score_model.dart';

class ScoreRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> upsert(ScoreModel score) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      DatabaseHelper.tableScores,
      columns: ['id'],
      where: 'student_id = ? AND assignment_id = ?',
      whereArgs: [score.studentId, score.assignmentId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final existingId = existing.first['id'].toString();
      await db.update(
        DatabaseHelper.tableScores,
        score.toDto(),
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }

    final id = await db.insert(DatabaseHelper.tableScores, score.toDto());
    return id.toString();
  }

  Future<List<ScoreModel>> getScoresByStudentId(String studentId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableScores,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<List<ScoreModel>> getScoresByAssignmentId(String assignmentId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableScores,
      where: 'assignment_id = ?',
      whereArgs: [assignmentId],
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<ScoreModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableScores,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScoreModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(ScoreModel score) async {
    if (score.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableScores,
      score.toDto(),
      where: 'id = ?',
      whereArgs: [score.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableScores,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScoreModel>> getScoresByClassId(String classId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT sc.*
      FROM ${DatabaseHelper.tableScores} sc
      INNER JOIN ${DatabaseHelper.tableAssignments} a
        ON a.id = sc.assignment_id
      WHERE a.class_id = ?
      ''',
      [classId],
    );
    return rows
        .map((row) => ScoreModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<double> getAverageScoreByStudentId(String studentId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT sc.points_earned, a.max_points
      FROM ${DatabaseHelper.tableScores} sc
      INNER JOIN ${DatabaseHelper.tableAssignments} a
        ON a.id = sc.assignment_id
      WHERE sc.student_id = ?
      ''',
      [studentId],
    );
    if (rows.isEmpty) return 0.0;

    double totalEarned = 0;
    double totalMax = 0;
    for (final row in rows) {
      totalEarned += double.tryParse(row['points_earned'].toString()) ?? 0.0;
      totalMax += double.tryParse(row['max_points'].toString()) ?? 0.0;
    }

    return totalMax > 0 ? (totalEarned / totalMax) * 100 : 0.0;
  }
}
