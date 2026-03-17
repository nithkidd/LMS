import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assessment_model.dart';
import '../models/folder_model.dart';
import '../models/grade_model.dart';
import '../models/trellis_class_model.dart';

final trellisDatabaseServiceProvider = Provider<TrellisDatabaseService>((ref) {
  return TrellisDatabaseService();
});

/// Firestore schema
/// folders/{folderId}
/// classes/{classId}
/// assessments/{assessmentId}
/// grades/{gradeId}
class TrellisDatabaseService {
  static const foldersCollection = 'folders';
  static const classesCollection = 'classes';
  static const assessmentsCollection = 'assessments';
  static const gradesCollection = 'grades';

  final FirebaseFirestore _firestore;

  TrellisDatabaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _folders =>
      _firestore.collection(foldersCollection);

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection(classesCollection);

  CollectionReference<Map<String, dynamic>> get _assessments =>
      _firestore.collection(assessmentsCollection);

  CollectionReference<Map<String, dynamic>> get _grades =>
      _firestore.collection(gradesCollection);

  Future<FolderModel> createFolder({
    required String teacherId,
    required String name,
    required String colorHex,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Folder name cannot be empty.');
    }

    final document = _folders.doc();
    final folder = FolderModel(
      id: document.id,
      teacherId: teacherId,
      name: trimmedName,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    await document.set(folder.toMap());
    return folder;
  }

  Future<void> moveClassToFolder(String classId, String? newFolderId) async {
    final classDocument = await _classes.doc(classId).get();
    if (!classDocument.exists) {
      throw StateError('Class $classId was not found.');
    }

    final classModel = TrellisClassModel.fromMap(
      classDocument.data() ?? const {},
      documentId: classDocument.id,
    );

    if (newFolderId != null) {
      final folderDocument = await _folders.doc(newFolderId).get();
      if (!folderDocument.exists) {
        throw StateError('Folder $newFolderId was not found.');
      }

      final folder = FolderModel.fromDocument(folderDocument);
      if (folder.teacherId != classModel.teacherId) {
        throw StateError(
          'Class $classId cannot be moved into folder $newFolderId because they belong to different teachers.',
        );
      }
    }

    await _classes.doc(classId).update({'folderId': newFolderId});
  }

  Future<void> saveStudentGrades(List<GradeModel> grades) async {
    if (grades.isEmpty) {
      return;
    }

    final firstAssessmentId = grades.first.assessmentId;
    final firstClassId = grades.first.classId;
    for (final grade in grades) {
      if (grade.assessmentId != firstAssessmentId) {
        throw ArgumentError(
          'saveStudentGrades expects all grades to belong to the same assessment.',
        );
      }
      if (grade.classId != firstClassId) {
        throw ArgumentError(
          'saveStudentGrades expects all grades to belong to the same class.',
        );
      }
    }

    final batch = _firestore.batch();
    for (final grade in grades) {
      final documentId =
          grade.id ??
          GradeModel.buildDocumentId(
            assessmentId: grade.assessmentId,
            studentId: grade.studentId,
          );
      final document = _grades.doc(documentId);
      final gradeToPersist = grade.copyWith(id: document.id);
      batch.set(document, gradeToPersist.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<double> calculateStudentFinalGrade(
    String studentId,
    String classId,
  ) async {
    final classDocument = await _classes.doc(classId).get();
    if (!classDocument.exists) {
      throw StateError('Class $classId was not found.');
    }

    final classModel = TrellisClassModel.fromMap(
      classDocument.data() ?? const {},
      documentId: classDocument.id,
    );

    final gradeSnapshot = await _grades
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .get();

    final grades = gradeSnapshot.docs
        .map(
          (document) =>
              GradeModel.fromMap(document.data(), documentId: document.id),
        )
        .where((grade) => !grade.isExcused)
        .toList();

    if (grades.isEmpty) {
      return 0;
    }

    final assessmentIds = grades
        .map((grade) => grade.assessmentId)
        .toSet()
        .toList(growable: false);

    final assessmentDocuments = await Future.wait(
      assessmentIds.map((assessmentId) => _assessments.doc(assessmentId).get()),
    );

    final assessmentsById = <String, AssessmentModel>{};
    for (final document in assessmentDocuments) {
      if (!document.exists) {
        throw StateError(
          'Assessment ${document.id} referenced by a stored grade could not be found.',
        );
      }

      final assessment = AssessmentModel.fromDocument(document);
      if (assessment.classId != classId) {
        throw StateError(
          'Assessment ${assessment.id} does not belong to class $classId.',
        );
      }
      assessmentsById[document.id] = assessment;
    }

    return calculateWeightedFinalGrade(
      classModel: classModel,
      grades: grades,
      assessmentsById: assessmentsById,
    );
  }

  static double calculateWeightedFinalGrade({
    required TrellisClassModel classModel,
    required Iterable<GradeModel> grades,
    required Map<String, AssessmentModel> assessmentsById,
  }) {
    if (classModel.formativeWeight < 0 || classModel.summativeWeight < 0) {
      throw StateError('Class weights must be non-negative.');
    }

    var formativeEarned = 0.0;
    var formativePossible = 0.0;
    var summativeEarned = 0.0;
    var summativePossible = 0.0;

    for (final grade in grades) {
      if (grade.isExcused) {
        continue;
      }

      final assessment = assessmentsById[grade.assessmentId];
      if (assessment == null) {
        throw StateError(
          'Missing assessment ${grade.assessmentId} for grade calculation.',
        );
      }
      if (assessment.maxScore <= 0) {
        continue;
      }

      if (assessment.type == AssessmentType.formative) {
        formativeEarned += grade.score;
        formativePossible += assessment.maxScore;
      } else {
        summativeEarned += grade.score;
        summativePossible += assessment.maxScore;
      }
    }

    final buckets =
        <_WeightedBucket>[
              _WeightedBucket(
                percentage: formativePossible > 0
                    ? (formativeEarned / formativePossible) * 100
                    : null,
                weight: classModel.formativeWeight,
              ),
              _WeightedBucket(
                percentage: summativePossible > 0
                    ? (summativeEarned / summativePossible) * 100
                    : null,
                weight: classModel.summativeWeight,
              ),
            ]
            .where((bucket) => bucket.percentage != null && bucket.weight > 0)
            .toList();

    if (buckets.isEmpty) {
      return 0;
    }

    final appliedWeight = buckets.fold<double>(
      0,
      (totalWeight, bucket) => totalWeight + bucket.weight,
    );
    if (appliedWeight <= 0) {
      return 0;
    }

    final weightedScore = buckets.fold<double>(
      0,
      (totalScore, bucket) => totalScore + (bucket.percentage! * bucket.weight),
    );

    return weightedScore / appliedWeight;
  }
}

class _WeightedBucket {
  final double? percentage;
  final double weight;

  const _WeightedBucket({required this.percentage, required this.weight});
}
