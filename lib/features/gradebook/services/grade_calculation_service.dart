import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../assignments/models/assignment_model.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../../students/models/student_model.dart';
import '../../students/providers/student_provider.dart';
import '../../subjects/models/subject_model.dart';
import '../../subjects/providers/subject_provider.dart';
import '../models/student_score.dart';
import '../providers/score_provider.dart';

class AssignmentScoreEntry {
  final AssignmentModel assignment;
  final double? currentScore;

  const AssignmentScoreEntry({required this.assignment, this.currentScore});
}

class SubjectTeacherRow {
  final StudentModel student;
  final Map<String, double> monthlyPercentages;
  final Map<String, double> monthlyRawScores;
  final Map<String, List<AssignmentScoreEntry>> monthlyEntries;
  final double sem1Average;
  final double sem2Average;
  final double yearlyAverage;
  final AssignmentScoreEntry? sem1OverrideEntry;
  final AssignmentScoreEntry? sem2OverrideEntry;
  final AssignmentScoreEntry? yearlyOverrideEntry;

  const SubjectTeacherRow({
    required this.student,
    required this.monthlyPercentages,
    required this.monthlyRawScores,
    required this.monthlyEntries,
    required this.sem1Average,
    required this.sem2Average,
    required this.yearlyAverage,
    this.sem1OverrideEntry,
    this.sem2OverrideEntry,
    this.yearlyOverrideEntry,
  });
}

class RankedStudentScore {
  final StudentScore studentScore;
  final double totalScore;
  final double averageScore;
  final String mention;
  final int rank;

  const RankedStudentScore({
    required this.studentScore,
    required this.totalScore,
    required this.averageScore,
    required this.mention,
    required this.rank,
  });
}

class ClassAdviserRow {
  final StudentModel student;
  final StudentScore studentScore;
  final Map<String, double> subjectScoresBySubjectId;
  final double totalScore;
  final double averageScore;
  final String mention;
  final int rank;

  const ClassAdviserRow({
    required this.student,
    required this.studentScore,
    required this.subjectScoresBySubjectId,
    required this.totalScore,
    required this.averageScore,
    required this.mention,
    required this.rank,
  });

  Map<String, double> get subjectYearlyAverages => subjectScoresBySubjectId;
  double get overallPercentage => averageScore;
  String get grade => mention;
  String get resultStatus => averageScore >= 25.0 ? 'ជាប់' : 'ធ្លាក់';
}

class AdvisorRankingPrintRow {
  final int rank;
  final String fullName;
  final double totalScore;
  final double averageScore;
  final String mention;
  final String resultStatus;

  const AdvisorRankingPrintRow({
    required this.rank,
    required this.fullName,
    required this.totalScore,
    required this.averageScore,
    required this.mention,
    required this.resultStatus,
  });

  factory AdvisorRankingPrintRow.fromAdviserRow(ClassAdviserRow row) {
    return AdvisorRankingPrintRow(
      rank: row.rank,
      fullName: row.student.name,
      totalScore: row.totalScore,
      averageScore: row.averageScore,
      mention: row.mention,
      resultStatus: row.resultStatus,
    );
  }
}

class AdvisorRankingPrintData {
  final List<AdvisorRankingPrintRow> rows;

  const AdvisorRankingPrintData({required this.rows});

  factory AdvisorRankingPrintData.empty() {
    return const AdvisorRankingPrintData(rows: []);
  }
}

class GradeCalculationData {
  final List<SubjectModel> subjects;
  final List<ClassAdviserRow> adviserRows;
  final AdvisorRankingPrintData advisorRankingPrintData;
  final Map<String, List<SubjectTeacherRow>> subjectTeacherRows;
  final ClassSummary classSummary;
  final double totalCoefficient;

  const GradeCalculationData({
    required this.subjects,
    required this.adviserRows,
    required this.advisorRankingPrintData,
    required this.subjectTeacherRows,
    required this.classSummary,
    this.totalCoefficient = 15.5,
  });
}

enum _SubjectScoreKey {
  khmer,
  civics,
  history,
  geography,
  math,
  physics,
  chemistry,
  biology,
  earthScience,
  foreignLanguage,
  economics,
  art,
  pe,
  chinese,
}

const List<_SubjectScoreKey> _subjectScoreOrder = [
  _SubjectScoreKey.khmer,
  _SubjectScoreKey.civics,
  _SubjectScoreKey.history,
  _SubjectScoreKey.geography,
  _SubjectScoreKey.math,
  _SubjectScoreKey.physics,
  _SubjectScoreKey.chemistry,
  _SubjectScoreKey.biology,
  _SubjectScoreKey.earthScience,
  _SubjectScoreKey.foreignLanguage,
  _SubjectScoreKey.economics,
  _SubjectScoreKey.art,
  _SubjectScoreKey.pe,
  _SubjectScoreKey.chinese,
];

final gradeProcessingServiceProvider = Provider<GradeProcessingService>((ref) {
  return const GradeProcessingService();
});

class GradeProcessingService {
  const GradeProcessingService();

  double calculateTotalScore(StudentScore studentScore) {
    return studentScore.totalScore;
  }

  double calculateAverageScore(
    StudentScore studentScore, {
    double totalCoefficient = 15.5,
  }) {
    return studentScore.averageScore(totalCoefficient: totalCoefficient);
  }

  List<RankedStudentScore> rankStudents(
    List<StudentScore> studentScores, {
    double totalCoefficient = 15.5,
  }) {
    final indexedScores =
        studentScores
            .asMap()
            .entries
            .where((entry) => _isValidStudent(entry.value))
            .map(
              (entry) => _IndexedStudentScore(
                originalIndex: entry.key,
                studentScore: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final totalCompare = calculateTotalScore(
              b.studentScore,
            ).compareTo(calculateTotalScore(a.studentScore));
            if (totalCompare != 0) {
              return totalCompare;
            }
            return a.originalIndex.compareTo(b.originalIndex);
          });

    final rankedScores = <RankedStudentScore>[];
    double? previousTotalScore;
    var currentRank = 1;

    for (var index = 0; index < indexedScores.length; index++) {
      final studentScore = indexedScores[index].studentScore;
      final totalScore = calculateTotalScore(studentScore);

      if (previousTotalScore != null && totalScore != previousTotalScore) {
        currentRank = index + 1;
      }

      rankedScores.add(
        RankedStudentScore(
          studentScore: studentScore,
          totalScore: totalScore,
          averageScore: calculateAverageScore(
            studentScore,
            totalCoefficient: totalCoefficient,
          ),
          mention: studentScore.mention(totalCoefficient: totalCoefficient),
          rank: currentRank,
        ),
      );

      previousTotalScore = totalScore;
    }

    return rankedScores;
  }

  ClassSummary buildClassSummary(
    List<StudentScore> studentScores, {
    double totalCoefficient = 15.5,
  }) {
    final validStudents = studentScores.where(_isValidStudent).toList();
    final mentionCounts = <String, int>{
      'ល្អ': 0,
      'ល្អបង្គួរ': 0,
      'មធ្យម': 0,
      'ខ្សោយ': 0,
    };

    for (final studentScore in validStudents) {
      final mention = studentScore.mention(totalCoefficient: totalCoefficient);
      mentionCounts[mention] = (mentionCounts[mention] ?? 0) + 1;
    }

    return ClassSummary(
      totalStudents: validStudents.length,
      femaleStudents: validStudents.where((student) => student.isFemale).length,
      mentionCounts: mentionCounts,
    );
  }

  List<ClassAdviserRow> buildRankedAdviserRows({
    required List<StudentModel> students,
    required List<SubjectModel> subjects,
    required Map<String, Map<String, double>> subjectScoresByStudentId,
    double totalCoefficient = 15.5,
  }) {
    final subjectKeyBySubjectId = _buildSubjectKeyBySubjectId(subjects);
    final studentByScoreId = <String, StudentModel>{};
    final subjectValuesByScoreId = <String, Map<String, double>>{};
    final studentScores = <StudentScore>[];

    for (var index = 0; index < students.length; index++) {
      final student = students[index];
      final studentKey = _studentKey(student, index);
      final subjectScores =
          subjectScoresByStudentId[studentKey] ?? const <String, double>{};
      final studentScore = _buildStudentScore(
        studentKey: studentKey,
        fullName: student.name,
        subjects: subjects,
        subjectScoresBySubjectId: subjectScores,
        subjectKeyBySubjectId: subjectKeyBySubjectId,
      );

      studentByScoreId[studentKey] = student;
      subjectValuesByScoreId[studentKey] = {
        for (final subject in subjects)
          if (subject.id != null) subject.id!: subjectScores[subject.id!] ?? 0,
      };
      studentScores.add(studentScore);
    }

    final rankedStudentScores = rankStudents(
      studentScores,
      totalCoefficient: totalCoefficient,
    );

    return rankedStudentScores
        .map((rankedScore) {
          final student = studentByScoreId[rankedScore.studentScore.id];
          if (student == null) {
            return null;
          }

          return ClassAdviserRow(
            student: student,
            studentScore: rankedScore.studentScore,
            subjectScoresBySubjectId:
                subjectValuesByScoreId[rankedScore.studentScore.id] ??
                const <String, double>{},
            totalScore: rankedScore.totalScore,
            averageScore: rankedScore.averageScore,
            mention: rankedScore.mention,
            rank: rankedScore.rank,
          );
        })
        .whereType<ClassAdviserRow>()
        .toList();
  }

  AdvisorRankingPrintData buildAdvisorRankingPrintData(
    List<ClassAdviserRow> adviserRows,
  ) {
    if (adviserRows.isEmpty) {
      return AdvisorRankingPrintData.empty();
    }

    final sortedRows = adviserRows.asMap().entries.toList()
      ..sort((a, b) {
        final rankCompare = a.value.rank.compareTo(b.value.rank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        return a.key.compareTo(b.key);
      });

    final printRows = sortedRows
        .map((entry) => AdvisorRankingPrintRow.fromAdviserRow(entry.value))
        .toList(growable: false);

    return AdvisorRankingPrintData(rows: printRows);
  }

  StudentScore _buildStudentScore({
    required String studentKey,
    required String fullName,
    required List<SubjectModel> subjects,
    required Map<String, double> subjectScoresBySubjectId,
    required Map<String, _SubjectScoreKey> subjectKeyBySubjectId,
  }) {
    final values = <_SubjectScoreKey, double?>{};

    for (final subject in subjects) {
      final subjectId = subject.id;
      if (subjectId == null) {
        continue;
      }

      final subjectKey = subjectKeyBySubjectId[subjectId];
      if (subjectKey == null) {
        continue;
      }

      values[subjectKey] = subjectScoresBySubjectId[subjectId];
    }

    return StudentScore(
      id: studentKey,
      fullName: fullName,
      khmer: values[_SubjectScoreKey.khmer],
      civics: values[_SubjectScoreKey.civics],
      history: values[_SubjectScoreKey.history],
      geography: values[_SubjectScoreKey.geography],
      math: values[_SubjectScoreKey.math],
      physics: values[_SubjectScoreKey.physics],
      chemistry: values[_SubjectScoreKey.chemistry],
      biology: values[_SubjectScoreKey.biology],
      earthScience: values[_SubjectScoreKey.earthScience],
      foreignLanguage: values[_SubjectScoreKey.foreignLanguage],
      economics: values[_SubjectScoreKey.economics],
      art: values[_SubjectScoreKey.art],
      pe: values[_SubjectScoreKey.pe],
      chinese: values[_SubjectScoreKey.chinese],
    );
  }

  Map<String, _SubjectScoreKey> _buildSubjectKeyBySubjectId(
    List<SubjectModel> subjects,
  ) {
    final keysBySubjectId = <String, _SubjectScoreKey>{};
    final usedKeys = <_SubjectScoreKey>{};

    for (final subject in subjects) {
      final subjectId = subject.id;
      if (subjectId == null) {
        continue;
      }

      final resolvedKey = _resolveSubjectKey(subject.name);
      if (resolvedKey == null || usedKeys.contains(resolvedKey)) {
        continue;
      }

      keysBySubjectId[subjectId] = resolvedKey;
      usedKeys.add(resolvedKey);
    }

    final remainingKeys = _subjectScoreOrder
        .where((subjectKey) => !usedKeys.contains(subjectKey))
        .toList();

    for (final subject in subjects) {
      final subjectId = subject.id;
      if (subjectId == null ||
          keysBySubjectId.containsKey(subjectId) ||
          remainingKeys.isEmpty) {
        continue;
      }

      keysBySubjectId[subjectId] = remainingKeys.removeAt(0);
    }

    return keysBySubjectId;
  }

  _SubjectScoreKey? _resolveSubjectKey(String rawSubjectName) {
    final normalizedName = _normalizeSubjectName(rawSubjectName);
    if (normalizedName.isEmpty) {
      return null;
    }

    final defaultSubjectIndex = kAdviserDefaultSubjects.indexWhere(
      (subjectName) => _normalizeSubjectName(subjectName) == normalizedName,
    );
    if (defaultSubjectIndex >= 0 &&
        defaultSubjectIndex < _subjectScoreOrder.length) {
      return _subjectScoreOrder[defaultSubjectIndex];
    }

    for (final entry in _subjectAliases.entries) {
      if (entry.value.contains(normalizedName)) {
        return entry.key;
      }
    }

    return null;
  }

  bool _isValidStudent(StudentScore studentScore) {
    return studentScore.fullName.trim().isNotEmpty;
  }

  String _studentKey(StudentModel student, int index) {
    final trimmedId = student.id?.trim();
    if (trimmedId != null && trimmedId.isNotEmpty) {
      return trimmedId;
    }
    return 'student-$index-${student.name.trim()}';
  }

  String _normalizeSubjectName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_./()]+'), '');
  }
}

const Map<_SubjectScoreKey, Set<String>> _subjectAliases = {
  _SubjectScoreKey.khmer: {'khmer', 'khmerlanguage', 'languagekhmer'},
  _SubjectScoreKey.civics: {
    'civics',
    'civiceducation',
    'moralcivics',
    'ethicscivics',
    'moraleducationcivics',
  },
  _SubjectScoreKey.history: {'history'},
  _SubjectScoreKey.geography: {'geography'},
  _SubjectScoreKey.math: {'math', 'mathematics'},
  _SubjectScoreKey.physics: {'physics'},
  _SubjectScoreKey.chemistry: {'chemistry'},
  _SubjectScoreKey.biology: {'biology'},
  _SubjectScoreKey.earthScience: {
    'earthscience',
    'earth',
    'geology',
    'earthstudies',
  },
  _SubjectScoreKey.foreignLanguage: {
    'foreignlanguage',
    'languageforeign',
    'english',
    'french',
  },
  _SubjectScoreKey.economics: {'economics', 'economic', 'homeeconomics'},
  _SubjectScoreKey.art: {'art', 'arts', 'fineart', 'finearts'},
  _SubjectScoreKey.pe: {
    'pe',
    'physicaleducation',
    'sport',
    'sports',
    'physicaleducationandsport',
  },
  _SubjectScoreKey.chinese: {'chinese', 'mandarin'},
};

class _IndexedStudentScore {
  final int originalIndex;
  final StudentScore studentScore;

  const _IndexedStudentScore({
    required this.originalIndex,
    required this.studentScore,
  });
}

class _SubjectTeacherComputation {
  final Map<String, List<SubjectTeacherRow>> subjectTeacherRows;
  final Map<String, Map<String, double>> subjectScoresByStudentId;

  const _SubjectTeacherComputation({
    required this.subjectTeacherRows,
    required this.subjectScoresByStudentId,
  });
}

final gradeCalculationProvider =
    FutureProvider.family<GradeCalculationData, String>((ref, classId) async {
      const totalCoefficient = 15.5;

      ref.watch(studentNotifierProvider);
      ref.watch(subjectNotifierProvider);
      ref.watch(assignmentNotifierProvider);
      ref.watch(scoreNotifierProvider);

      final studentRepository = ref.read(studentRepositoryProvider);
      final subjectRepository = ref.read(subjectRepositoryProvider);
      final assignmentRepository = ref.read(assignmentRepositoryProvider);
      final scoreRepository = ref.read(scoreRepositoryProvider);
      final processingService = ref.read(gradeProcessingServiceProvider);
      final results = await Future.wait<dynamic>([
        studentRepository.getStudentsByClassId(classId),
        subjectRepository.getByClassId(classId),
        assignmentRepository.getByClassId(classId),
        scoreRepository.getScoresByClassId(classId),
      ]);

      final students = results[0] as List<StudentModel>;
      final subjects = results[1] as List<SubjectModel>;
      final assignments = results[2] as List<AssignmentModel>;
      final allScores = results[3] as List;

      final scoresByAssignmentAndStudent = <String, Map<String, double>>{};
      for (final score in allScores) {
        scoresByAssignmentAndStudent.putIfAbsent(score.assignmentId, () => {});
        scoresByAssignmentAndStudent[score.assignmentId]![score.studentId] =
            score.pointsEarned;
      }

      final subjectTeacherComputation = _buildSubjectTeacherComputation(
        students: students,
        subjects: subjects,
        assignments: assignments,
        scoresByAssignmentAndStudent: scoresByAssignmentAndStudent,
      );

      final adviserRows = processingService.buildRankedAdviserRows(
        students: students,
        subjects: subjects,
        subjectScoresByStudentId:
            subjectTeacherComputation.subjectScoresByStudentId,
        totalCoefficient: totalCoefficient,
      );
      final advisorRankingPrintData = processingService
          .buildAdvisorRankingPrintData(adviserRows);

      final classSummary = processingService.buildClassSummary(
        adviserRows.map((row) => row.studentScore).toList(),
        totalCoefficient: totalCoefficient,
      );

      return GradeCalculationData(
        subjects: subjects,
        adviserRows: adviserRows,
        advisorRankingPrintData: advisorRankingPrintData,
        subjectTeacherRows: subjectTeacherComputation.subjectTeacherRows,
        classSummary: classSummary,
        totalCoefficient: totalCoefficient,
      );
    });

_SubjectTeacherComputation _buildSubjectTeacherComputation({
  required List<StudentModel> students,
  required List<SubjectModel> subjects,
  required List<AssignmentModel> assignments,
  required Map<String, Map<String, double>> scoresByAssignmentAndStudent,
}) {
  final subjectTeacherRows = <String, List<SubjectTeacherRow>>{};
  final subjectScoresByStudentId = <String, Map<String, double>>{};

  const sem1Months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'};
  const sem2Months = {'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
  const overrideMonths = {'SEM1', 'SEM2', 'YEARLY'};

  for (var studentIndex = 0; studentIndex < students.length; studentIndex++) {
    final student = students[studentIndex];
    final studentKey = _studentKeyForProvider(student, studentIndex);
    subjectScoresByStudentId.putIfAbsent(studentKey, () => {});
  }

  for (final subject in subjects) {
    final subjectId = subject.id;
    if (subjectId == null) {
      continue;
    }

    final subjectAssignments = assignments
        .where((assignment) => assignment.subjectId == subjectId)
        .toList();
    final rows = <SubjectTeacherRow>[];

    for (var studentIndex = 0; studentIndex < students.length; studentIndex++) {
      final student = students[studentIndex];
      final studentKey = _studentKeyForProvider(student, studentIndex);

      final monthlyPercentages = <String, double>{};
      final monthlyRawScores = <String, double>{};
      final monthlyEntries = <String, List<AssignmentScoreEntry>>{};
      final monthlyMaxMap = <String, double>{};

      var sem1Earned = 0.0;
      var sem1Max = 0.0;
      var sem2Earned = 0.0;
      var sem2Max = 0.0;

      AssignmentScoreEntry? sem1OverrideEntry;
      AssignmentScoreEntry? sem2OverrideEntry;
      AssignmentScoreEntry? yearlyOverrideEntry;

      for (final assignment in subjectAssignments) {
        final assignmentId = assignment.id;
        if (assignmentId == null) {
          continue;
        }

        final pointsEarned =
            scoresByAssignmentAndStudent[assignmentId]?[studentKey];

        if (overrideMonths.contains(assignment.month)) {
          final entry = AssignmentScoreEntry(
            assignment: assignment,
            currentScore: pointsEarned,
          );
          if (assignment.month == 'SEM1') {
            sem1OverrideEntry = entry;
          } else if (assignment.month == 'SEM2') {
            sem2OverrideEntry = entry;
          } else if (assignment.month == 'YEARLY') {
            yearlyOverrideEntry = entry;
          }
          continue;
        }

        monthlyEntries.putIfAbsent(assignment.month, () => []);
        monthlyEntries[assignment.month]!.add(
          AssignmentScoreEntry(
            assignment: assignment,
            currentScore: pointsEarned,
          ),
        );

        monthlyMaxMap[assignment.month] =
            (monthlyMaxMap[assignment.month] ?? 0) + assignment.maxPoints;

        if (pointsEarned != null) {
          monthlyRawScores[assignment.month] =
              (monthlyRawScores[assignment.month] ?? 0) + pointsEarned;
          if (sem1Months.contains(assignment.month)) {
            sem1Earned += pointsEarned;
          } else if (sem2Months.contains(assignment.month)) {
            sem2Earned += pointsEarned;
          }
        }

        if (sem1Months.contains(assignment.month)) {
          sem1Max += assignment.maxPoints;
        } else if (sem2Months.contains(assignment.month)) {
          sem2Max += assignment.maxPoints;
        }
      }

      monthlyRawScores.forEach((month, earned) {
        final max = monthlyMaxMap[month] ?? 0;
        if (max > 0) {
          monthlyPercentages[month] = (earned / max) * 100;
        }
      });

      var sem1Average = sem1Max > 0 ? (sem1Earned / sem1Max) * 100 : 0.0;
      var sem2Average = sem2Max > 0 ? (sem2Earned / sem2Max) * 100 : 0.0;
      var yearlyAverage = (sem1Max + sem2Max) > 0
          ? ((sem1Earned + sem2Earned) / (sem1Max + sem2Max)) * 100
          : 0.0;

      if (sem1OverrideEntry?.currentScore != null) {
        final override = sem1OverrideEntry!;
        sem1Average =
            (override.currentScore! / override.assignment.maxPoints) * 100;
      }

      if (sem2OverrideEntry?.currentScore != null) {
        final override = sem2OverrideEntry!;
        sem2Average =
            (override.currentScore! / override.assignment.maxPoints) * 100;
      }

      if (yearlyOverrideEntry?.currentScore != null) {
        final override = yearlyOverrideEntry!;
        yearlyAverage =
            (override.currentScore! / override.assignment.maxPoints) * 100;
      }

      subjectScoresByStudentId[studentKey]![subjectId] = yearlyAverage;

      rows.add(
        SubjectTeacherRow(
          student: student,
          monthlyPercentages: monthlyPercentages,
          monthlyRawScores: monthlyRawScores,
          monthlyEntries: monthlyEntries,
          sem1Average: sem1Average,
          sem2Average: sem2Average,
          yearlyAverage: yearlyAverage,
          sem1OverrideEntry: sem1OverrideEntry,
          sem2OverrideEntry: sem2OverrideEntry,
          yearlyOverrideEntry: yearlyOverrideEntry,
        ),
      );
    }

    subjectTeacherRows[subjectId] = rows;
  }

  return _SubjectTeacherComputation(
    subjectTeacherRows: subjectTeacherRows,
    subjectScoresByStudentId: subjectScoresByStudentId,
  );
}

String _studentKeyForProvider(StudentModel student, int index) {
  final trimmedId = student.id?.trim();
  if (trimmedId != null && trimmedId.isNotEmpty) {
    return trimmedId;
  }
  return 'student-$index-${student.name.trim()}';
}
