import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/khmer_collator.dart';
import '../models/student_model.dart';
import '../repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

class StudentNotifier extends AsyncNotifier<List<StudentModel>> {
  String? _currentClassId;
  final Map<String, List<StudentModel>> _cache = {};

  @override
  FutureOr<List<StudentModel>> build() async {
    return [];
  }

  Future<void> loadStudentsForClass(String classId, {bool refresh = false}) async {
    _currentClassId = classId;
    final cachedStudents = _cache[classId];
    if (cachedStudents != null && !refresh) {
      state = AsyncValue.data(cachedStudents);
      return;
    }

    if (cachedStudents == null) {
      state = const AsyncValue.loading();
    } else {
      state = AsyncValue.data(cachedStudents);
    }

    final repository = ref.read(studentRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final students = await repository.getStudentsByClassId(classId);
      _cache[classId] = students;
      return students;
    });
  }

  Future<void> addStudent(
    String classId,
    String name, {
    String? sex,
    String? dateOfBirth,
    String? address,
    String? remarks,
  }) async {
    final repository = ref.read(studentRepositoryProvider);
    final newStudent = StudentModel(
      classId: classId,
      name: name,
      sex: sex,
      dateOfBirth: dateOfBirth,
      address: address,
      remarks: remarks,
    );
    final id = await repository.insert(newStudent);
    final targetClassId = _currentClassId ?? classId;
    final updatedStudents = _sortedStudents([
      ..._cache[targetClassId] ?? const <StudentModel>[],
      newStudent.copyWith(id: id),
    ]);

    _cache[targetClassId] = updatedStudents;
    state = AsyncValue.data(updatedStudents);
  }

  Future<void> deleteStudent(String id) async {
    if (_currentClassId == null) return;

    final repository = ref.read(studentRepositoryProvider);
    await repository.delete(id);

    final updatedStudents = (_cache[_currentClassId!] ?? const <StudentModel>[])
        .where((student) => student.id != id)
        .toList(growable: false);

    _cache[_currentClassId!] = updatedStudents;
    state = AsyncValue.data(updatedStudents);
  }

  Future<void> updateStudent(StudentModel updatedStudent) async {
    if (_currentClassId == null) return;

    final repository = ref.read(studentRepositoryProvider);
    await repository.update(updatedStudent);

    final updatedStudents = _sortedStudents(
      (_cache[_currentClassId!] ?? const <StudentModel>[])
          .map((student) => student.id == updatedStudent.id ? updatedStudent : student)
          .toList(growable: false),
    );

    _cache[_currentClassId!] = updatedStudents;
    state = AsyncValue.data(updatedStudents);
  }

  List<StudentModel> _sortedStudents(List<StudentModel> students) {
    final sorted = students.toList(growable: false);
    KhmerCollator.sortBy(sorted, (student) => student.name);
    return sorted;
  }
}

final studentNotifierProvider =
    AsyncNotifierProvider<StudentNotifier, List<StudentModel>>(() {
      return StudentNotifier();
    });
