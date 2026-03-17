import '../../../core/database/database_helper.dart';
import '../models/school_model.dart';

class SchoolRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> insert(SchoolModel school) async {
    final db = await _dbHelper.database;
    final id = await db.insert(DatabaseHelper.tableSchools, school.toDto());
    return id.toString();
  }

  Future<List<SchoolModel>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DatabaseHelper.tableSchools);

    final schools = rows
        .map((row) => SchoolModel.fromDto(row, row['id'].toString()))
        .toList();

    schools.sort((a, b) {
      final orderCompare = b.displayOrder.compareTo(a.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
    });

    return schools;
  }

  Future<void> updateDisplayOrder(String id, int displayOrder) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableSchools,
      {'display_order': displayOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SchoolModel?> getById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableSchools,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SchoolModel.fromDto(rows.first, rows.first['id'].toString());
  }

  Future<void> update(SchoolModel school) async {
    if (school.id == null) return;

    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableSchools,
      school.toDto(),
      where: 'id = ?',
      whereArgs: [school.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableSchools,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
