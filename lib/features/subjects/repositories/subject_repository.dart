import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(SubjectModel subject) async {
    final db = await _dbHelper.database;
    var nextOrder = subject.displayOrder;

    if (nextOrder == null) {
      final result = await db.rawQuery(
        '''
        SELECT MAX(display_order) AS max_order
        FROM ${DatabaseHelper.tableSubjects}
        WHERE class_id = ?
        ''',
        [subject.classId],
      );
      final maxOrder = result.first['max_order'];
      nextOrder = maxOrder == null ? 0 : int.parse(maxOrder.toString()) + 1;
    }

    final id = await db.insert(
      DatabaseHelper.tableSubjects,
      subject.copyWith(displayOrder: nextOrder).toDto(),
    );
    return id.toString();
  }

  Future<List<SubjectModel>> getByClassId(String classId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'display_order ASC, id ASC',
    );

    return rows
        .map((row) => SubjectModel.fromDto(row, row['id'].toString()))
        .toList();
  }

  Future<SubjectModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SubjectModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(SubjectModel subject) async {
    if (subject.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableSubjects,
      subject.toDto(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderSubjects({
    required String classId,
    required List<SubjectModel> orderedSubjects,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (var index = 0; index < orderedSubjects.length; index++) {
        final subjectId = orderedSubjects[index].id;
        if (subjectId == null) continue;

        await txn.update(
          DatabaseHelper.tableSubjects,
          {'display_order': index},
          where: 'id = ? AND class_id = ?',
          whereArgs: [subjectId, classId],
        );
      }
    });
  }
}
