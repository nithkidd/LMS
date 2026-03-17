import 'package:flutter_test/flutter_test.dart';
import 'package:trellis/features/trellis/models/assessment_model.dart';
import 'package:trellis/features/trellis/models/grade_model.dart';
import 'package:trellis/features/trellis/models/trellis_class_model.dart';
import 'package:trellis/features/trellis/services/trellis_database_service.dart';

void main() {
  group('TrellisDatabaseService.calculateWeightedFinalGrade', () {
    test('ignores excused grades and applies weighted category math', () {
      final classModel = TrellisClassModel(
        id: 'class_1',
        teacherId: 'teacher_1',
        folderId: 'folder_1',
        name: 'Biology',
        academicYear: '2025-2026',
        formativeWeight: 0.4,
        summativeWeight: 0.6,
      );

      final assessmentsById = {
        'a1': AssessmentModel(
          id: 'a1',
          classId: 'class_1',
          title: 'Quiz 1',
          date: DateTime(2026, 1, 10),
          type: AssessmentType.formative,
          maxScore: 20,
        ),
        'a2': AssessmentModel(
          id: 'a2',
          classId: 'class_1',
          title: 'Midterm',
          date: DateTime(2026, 1, 25),
          type: AssessmentType.summative,
          maxScore: 100,
        ),
        'a3': AssessmentModel(
          id: 'a3',
          classId: 'class_1',
          title: 'Practice',
          date: DateTime(2026, 1, 12),
          type: AssessmentType.formative,
          maxScore: 10,
        ),
      };

      final finalGrade = TrellisDatabaseService.calculateWeightedFinalGrade(
        classModel: classModel,
        grades: const [
          GradeModel(
            id: 'g1',
            assessmentId: 'a1',
            studentId: 'student_1',
            classId: 'class_1',
            score: 16,
          ),
          GradeModel(
            id: 'g2',
            assessmentId: 'a2',
            studentId: 'student_1',
            classId: 'class_1',
            score: 75,
          ),
          GradeModel(
            id: 'g3',
            assessmentId: 'a3',
            studentId: 'student_1',
            classId: 'class_1',
            score: 0,
            isExcused: true,
          ),
        ],
        assessmentsById: assessmentsById,
      );

      expect(finalGrade, closeTo(77, 0.001));
    });

    test(
      'normalizes to available categories when only one category exists',
      () {
        final classModel = TrellisClassModel(
          id: 'class_1',
          teacherId: 'teacher_1',
          folderId: null,
          name: 'Biology',
          academicYear: '2025-2026',
          formativeWeight: 40,
          summativeWeight: 60,
        );

        final finalGrade = TrellisDatabaseService.calculateWeightedFinalGrade(
          classModel: classModel,
          grades: const [
            GradeModel(
              id: 'g1',
              assessmentId: 'a1',
              studentId: 'student_1',
              classId: 'class_1',
              score: 18,
            ),
          ],
          assessmentsById: {
            'a1': AssessmentModel(
              id: 'a1',
              classId: 'class_1',
              title: 'Quiz 1',
              date: DateTime(2026, 1, 10),
              type: AssessmentType.formative,
              maxScore: 20,
            ),
          },
        );

        expect(finalGrade, closeTo(90, 0.001));
      },
    );
  });
}
