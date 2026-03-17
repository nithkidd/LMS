import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../repositories/assignment_repository.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository();
});

class AssignmentNotifier extends AsyncNotifier<List<AssignmentModel>> {
  String? _currentClassId;
  final Map<String, List<AssignmentModel>> _cache = {};

  @override
  FutureOr<List<AssignmentModel>> build() async {
    return [];
  }

  Future<void> loadAssignmentsForClass(
    String classId, {
    bool refresh = false,
  }) async {
    _currentClassId = classId;
    final cachedAssignments = _cache[classId];
    if (cachedAssignments != null && !refresh) {
      state = AsyncValue.data(cachedAssignments);
      return;
    }

    if (cachedAssignments == null) {
      state = const AsyncValue.loading();
    } else {
      state = AsyncValue.data(cachedAssignments);
    }

    final repository = ref.read(assignmentRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final assignments = await repository.getByClassId(classId);
      _cache[classId] = assignments;
      return assignments;
    });
  }

  Future<void> addAssignment(
    String classId,
    String subjectId,
    String name,
    String month,
    String year,
    double maxPoints,
  ) async {
    final repository = ref.read(assignmentRepositoryProvider);
    final newAssignment = AssignmentModel(
      classId: classId,
      subjectId: subjectId,
      name: name,
      month: month,
      year: year,
      maxPoints: maxPoints,
    );
    final id = await repository.insert(newAssignment);
    final targetClassId = _currentClassId ?? classId;
    final updatedAssignments = _sortedAssignments([
      ..._cache[targetClassId] ?? const <AssignmentModel>[],
      newAssignment.copyWith(id: id),
    ]);

    _cache[targetClassId] = updatedAssignments;
    state = AsyncValue.data(updatedAssignments);
  }

  Future<void> deleteAssignment(String id) async {
    if (_currentClassId == null) return;

    final repository = ref.read(assignmentRepositoryProvider);
    await repository.delete(id);

    final updatedAssignments =
        (_cache[_currentClassId!] ?? const <AssignmentModel>[])
            .where((assignment) => assignment.id != id)
            .toList(growable: false);

    _cache[_currentClassId!] = updatedAssignments;
    state = AsyncValue.data(updatedAssignments);
  }

  Future<void> updateAssignment(AssignmentModel updated) async {
    if (_currentClassId == null) return;

    final repository = ref.read(assignmentRepositoryProvider);
    await repository.update(updated);

    final updatedAssignments = _sortedAssignments(
      (_cache[_currentClassId!] ?? const <AssignmentModel>[])
          .map((assignment) => assignment.id == updated.id ? updated : assignment)
          .toList(growable: false),
    );

    _cache[_currentClassId!] = updatedAssignments;
    state = AsyncValue.data(updatedAssignments);
  }

  List<AssignmentModel> _sortedAssignments(List<AssignmentModel> assignments) {
    final sorted = assignments.toList(growable: false);
    sorted.sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) {
        return yearCompare;
      }
      return b.month.compareTo(a.month);
    });
    return sorted;
  }
}

final assignmentNotifierProvider =
    AsyncNotifierProvider<AssignmentNotifier, List<AssignmentModel>>(() {
      return AssignmentNotifier();
    });
