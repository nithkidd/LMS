import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score_model.dart';
import '../repositories/score_repository.dart';

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepository();
});

class ScoreNotifier extends AsyncNotifier<List<ScoreModel>> {
  int? _currentAssignmentId;

  @override
  FutureOr<List<ScoreModel>> build() async {
    return [];
  }

  // Used by the Batch Grading UI to load all scores for an assignment column
  Future<void> loadScoresForAssignment(int assignmentId) async {
    _currentAssignmentId = assignmentId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(scoreRepositoryProvider);
      return await repository.getScoresByAssignmentId(assignmentId);
    });
  }

  // Fast continuous upserts during batch grading
  Future<void> saveScoreForAssignment(int studentId, int assignmentId, double pointsEarned) async {
    final repository = ref.read(scoreRepositoryProvider);
    final newScore = ScoreModel(
      studentId: studentId,
      assignmentId: assignmentId,
      pointsEarned: pointsEarned,
    );
    await repository.upsert(newScore);
    
    // Refresh the column in the background seamlessly
    if (_currentAssignmentId == assignmentId) {
       final updatedScores = await repository.getScoresByAssignmentId(assignmentId);
       state = AsyncValue.data(updatedScores);
    }
  }

  Future<void> deleteScore(int id) async {
    if (_currentAssignmentId == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(scoreRepositoryProvider);
      await repository.delete(id);
      
      return await repository.getScoresByAssignmentId(_currentAssignmentId!);
    });
  }
}

final scoreNotifierProvider = AsyncNotifierProvider<ScoreNotifier, List<ScoreModel>>(() {
  return ScoreNotifier();
});

// A lightweight provider used by the Student Profile Page to fetch their individual average quickly
final studentScoreAverageProvider = FutureProvider.family<double, int>((ref, studentId) async {
  final repository = ref.read(scoreRepositoryProvider);
  return await repository.getAverageScoreByStudentId(studentId);
});
