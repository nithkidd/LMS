import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_teacher_subject_model.dart';
import '../repositories/class_teacher_subject_repository.dart';

final classTeacherSubjectRepositoryProvider =
    Provider<ClassTeacherSubjectRepository>((ref) {
      return ClassTeacherSubjectRepository();
    });

/// Get all subjects assigned to a specific teacher in a specific class
final teacherSubjectsProvider =
    FutureProvider.family<List<String>, (String classId, String teacherId)>((
      ref,
      params,
    ) async {
      final (classId, teacherId) = params;
      final repository = ref.read(classTeacherSubjectRepositoryProvider);
      return await repository.getAssignedSubjectIds(
        classId: classId,
        teacherId: teacherId,
      );
    });

/// Get all subjects with their assigned teachers for a class
final classSubjectTeachersProvider =
    FutureProvider.family<List<ClassTeacherSubjectRow>, String>((
      ref,
      classId,
    ) async {
      final repository = ref.read(classTeacherSubjectRepositoryProvider);
      return await repository.getSubjectsWithTeachers(classId: classId);
    });

class ClassTeacherSubjectNotifier
    extends AsyncNotifier<List<ClassTeacherSubjectModel>> {
  String? _currentClassId;
  String? _currentTeacherId;

  @override
  FutureOr<List<ClassTeacherSubjectModel>> build() async {
    return [];
  }

  Future<void> loadAssignmentsForTeacherClass({
    required String classId,
    required String teacherId,
  }) async {
    _currentClassId = classId;
    _currentTeacherId = teacherId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classTeacherSubjectRepositoryProvider);
      return await repository.getByClassAndTeacher(
        classId: classId,
        teacherId: teacherId,
      );
    });
  }

  Future<void> assignSubjectToTeacher({
    required String classId,
    required String teacherId,
    required String subjectId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classTeacherSubjectRepositoryProvider);
      final model = ClassTeacherSubjectModel(
        classId: classId,
        teacherId: teacherId,
        subjectId: subjectId,
      );
      await repository.insert(model);
      if (_currentClassId != null && _currentTeacherId != null) {
        return await repository.getByClassAndTeacher(
          classId: _currentClassId!,
          teacherId: _currentTeacherId!,
        );
      }
      return [];
    });
    ref.invalidate(teacherSubjectsProvider);
    ref.invalidate(classSubjectTeachersProvider);
  }

  Future<void> unassignSubjectFromTeacher({
    required String classId,
    required String teacherId,
    required String subjectId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(classTeacherSubjectRepositoryProvider);
      await repository.deleteByClassAndTeacherAndSubject(
        classId: classId,
        teacherId: teacherId,
        subjectId: subjectId,
      );
      if (_currentClassId != null && _currentTeacherId != null) {
        return await repository.getByClassAndTeacher(
          classId: _currentClassId!,
          teacherId: _currentTeacherId!,
        );
      }
      return [];
    });
    ref.invalidate(teacherSubjectsProvider);
    ref.invalidate(classSubjectTeachersProvider);
  }
}

final classTeacherSubjectNotifierProvider =
    AsyncNotifierProvider<
      ClassTeacherSubjectNotifier,
      List<ClassTeacherSubjectModel>
    >(() {
      return ClassTeacherSubjectNotifier();
    });
