import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/grade_calculation_service.dart';
import '../providers/score_provider.dart';
import '../providers/gradebook_permission_provider.dart';
import '../widgets/advisor_ranking_print_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../assignments/models/assignment_model.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../../students/models/student_model.dart';
import '../models/score_model.dart';

enum GradebookViewMode { classAdviser, subjectTeacher }

enum AdviserClassViewMode { scorebook, ranking }

const List<String> _adviserReportMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const Map<String, String> kMonthLabels = {
  'Jan': 'មករា',
  'Feb': 'កុម្ភៈ',
  'Mar': 'មីនា',
  'Apr': 'មេសា',
  'May': 'ឧសភា',
  'Jun': 'មិថុនា',
  'Jul': 'កក្កដា',
  'Aug': 'សីហា',
  'Sep': 'កញ្ញា',
  'Oct': 'តុលា',
  'Nov': 'វិច្ឆិកា',
  'Dec': 'ធ្នូ',
};

class GradebookMainTabWidget extends ConsumerStatefulWidget {
  final String classId;
  final String? teacherId; // null = admin, non-null = teacher view
  final bool isAdviser;

  const GradebookMainTabWidget({
    super.key,
    required this.classId,
    this.teacherId,
    this.isAdviser = false,
  });

  @override
  ConsumerState<GradebookMainTabWidget> createState() =>
      _GradebookMainTabWidgetState();
}

class _GradebookMainTabWidgetState
    extends ConsumerState<GradebookMainTabWidget> {
  late GradebookViewMode _viewMode;
  late AdviserClassViewMode _adviserViewMode;
  late String _selectedAdviserMonth;
  String? _selectedSubjectId;

  bool get _canAccessAdviserView => widget.isAdviser;

  @override
  void initState() {
    super.initState();
    // Only advisers can access class adviser view.
    _viewMode = _canAccessAdviserView
        ? GradebookViewMode.classAdviser
        : GradebookViewMode.subjectTeacher;
    _adviserViewMode = AdviserClassViewMode.scorebook;
    _selectedAdviserMonth = _adviserReportMonths[DateTime.now().month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final gradeDataState = ref.watch(gradeCalculationProvider(widget.classId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: gradeDataState.when(
        data: (data) {
          if (data.subjects.isEmpty) {
            return Center(
              child: Text(
                'សូមបន្ថែមមុខវិជ្ជាយ៉ាងតិចមួយនៅផ្ទាំងមុខវិជ្ជា\nដើម្បីមើលតារាងពិន្ទុ។',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          if (_viewMode == GradebookViewMode.subjectTeacher &&
              _selectedSubjectId == null) {
            _selectedSubjectId = data.subjects.first.id;
          }

          // Safety guard: never allow non-advisers to remain in adviser mode.
          if (!_canAccessAdviserView &&
              _viewMode == GradebookViewMode.classAdviser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _viewMode = GradebookViewMode.subjectTeacher;
                });
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlPanel(data),
              Expanded(
                child: _viewMode == GradebookViewMode.classAdviser
                    ? _buildClassAdviserView(data)
                    : _buildSubjectTeacherView(data),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('កំហុស៖ $err', style: TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Control Panel
  // ---------------------------------------------------------------------------

  Widget _buildControlPanel(GradeCalculationData data) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only advisers can switch to class adviser view.
                if (_canAccessAdviserView) ...[
                  const Text(
                    'របៀបបង្ហាញ៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  DropdownButton<GradebookViewMode>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: GradebookViewMode.classAdviser,
                        child: Text('គ្រូបន្ទុកថ្នាក់'),
                      ),
                      DropdownMenuItem(
                        value: GradebookViewMode.subjectTeacher,
                        child: Text('គ្រូមុខវិជ្ជា'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ] else ...[
                  // Non-adviser teachers see a static label
                  const Text(
                    'តារាងពិន្ទុ - មុខវិជ្ជារបស់អ្នក',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (_viewMode == GradebookViewMode.subjectTeacher) ...[
                  const SizedBox(height: AppSizes.paddingMd),
                  const Text(
                    'មុខវិជ្ជា៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  // Filter subjects based on teacher permissions
                  Builder(
                    builder: (context) {
                      // Get visible subjects for this teacher
                      final visibleSubjectsAsync = ref.watch(
                        gradebookVisibleSubjectsProvider((
                          data.subjects,
                          widget.classId,
                          widget.teacherId,
                          widget.isAdviser,
                        )),
                      );

                      return visibleSubjectsAsync.when(
                        data: (visibleSubjects) {
                          // Ensure selected subject is valid
                          if (_selectedSubjectId == null ||
                              !visibleSubjects.any(
                                (s) => s.id == _selectedSubjectId,
                              )) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (visibleSubjects.isNotEmpty) {
                                setState(
                                  () => _selectedSubjectId =
                                      visibleSubjects.first.id,
                                );
                              }
                            });
                          }

                          return DropdownButton<String>(
                            value: _selectedSubjectId,
                            underline: const SizedBox(),
                            items: visibleSubjects
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSubjectId = val);
                              }
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, st) => Text('Error: $err'),
                      );
                    },
                  ),
                ],
                if (_viewMode == GradebookViewMode.classAdviser &&
                    _canAccessAdviserView) ...[
                  const SizedBox(height: AppSizes.paddingMd),
                  const Text(
                    'ទិដ្ឋភាព',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _buildAdviserViewSwitcher(),
                  const SizedBox(height: AppSizes.paddingMd),
                  const Text(
                    'ខែ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  _buildAdviserMonthSelector(),
                ],
              ],
            )
          : Row(
              children: [
                // Only advisers can switch to class adviser view.
                if (_canAccessAdviserView) ...[
                  const Text(
                    'របៀបបង្ហាញ៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSizes.paddingSm),
                  DropdownButton<GradebookViewMode>(
                    value: _viewMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: GradebookViewMode.classAdviser,
                        child: Text('គ្រូបន្ទុកថ្នាក់'),
                      ),
                      DropdownMenuItem(
                        value: GradebookViewMode.subjectTeacher,
                        child: Text('គ្រូមុខវិជ្ជា'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewMode = val);
                    },
                  ),
                ] else ...[
                  // Non-adviser teachers see a static label
                  const Text(
                    'តារាងពិន្ទុ - មុខវិជ្ជារបស់អ្នក',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (_viewMode == GradebookViewMode.subjectTeacher) ...[
                  const SizedBox(width: AppSizes.paddingLg),
                  const Text(
                    'មុខវិជ្ជា៖',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSizes.paddingSm),
                  // Filter subjects based on teacher permissions
                  Builder(
                    builder: (context) {
                      // Get visible subjects for this teacher
                      final visibleSubjectsAsync = ref.watch(
                        gradebookVisibleSubjectsProvider((
                          data.subjects,
                          widget.classId,
                          widget.teacherId,
                          widget.isAdviser,
                        )),
                      );

                      return visibleSubjectsAsync.when(
                        data: (visibleSubjects) {
                          // Ensure selected subject is valid
                          if (_selectedSubjectId == null ||
                              !visibleSubjects.any(
                                (s) => s.id == _selectedSubjectId,
                              )) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (visibleSubjects.isNotEmpty) {
                                setState(
                                  () => _selectedSubjectId =
                                      visibleSubjects.first.id,
                                );
                              }
                            });
                          }

                          return DropdownButton<String>(
                            value: _selectedSubjectId,
                            underline: const SizedBox(),
                            items: visibleSubjects
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSubjectId = val);
                              }
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, st) => Text('Error: $err'),
                      );
                    },
                  ),
                ],
                if (_viewMode == GradebookViewMode.classAdviser &&
                    _canAccessAdviserView) ...[
                  const SizedBox(width: AppSizes.paddingLg),
                  _buildAdviserViewSwitcher(),
                  const SizedBox(width: AppSizes.paddingLg),
                  _buildAdviserMonthSelector(),
                ],
              ],
            ),
    );
  }

  Widget _buildAdviserViewSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AdviserClassViewMode>(
        segments: const [
          ButtonSegment<AdviserClassViewMode>(
            value: AdviserClassViewMode.scorebook,
            label: Text('តារាងបូងពិន្ទុប្រលងប្រចាំខែ'),
            icon: Icon(Icons.grid_view_rounded, size: 18),
          ),
          ButtonSegment<AdviserClassViewMode>(
            value: AdviserClassViewMode.ranking,
            label: Text('តារាងចំណាត់ថ្នាក់'),
            icon: Icon(Icons.leaderboard_rounded, size: 18),
          ),
        ],
        selected: {_adviserViewMode},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            setState(() => _adviserViewMode = selection.first);
          }
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.borderStrong),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviserMonthSelector() {
    return DropdownButton<String>(
      value: _selectedAdviserMonth,
      underline: const SizedBox(),
      items: _adviserReportMonths
          .map(
            (month) => DropdownMenuItem(
              value: month,
              child: Text(kMonthLabels[month] ?? month),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedAdviserMonth = value);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  //  Class Adviser View
  // ---------------------------------------------------------------------------

  Widget _buildClassAdviserView(GradeCalculationData data) {
    final monthlyRows = _buildMonthlyAdviserRows(data);
    return switch (_adviserViewMode) {
      AdviserClassViewMode.scorebook => _buildClassAdviserScorebookView(
        data,
        monthlyRows,
      ),
      AdviserClassViewMode.ranking => AdvisorRankingPrintView(
        data: AdvisorRankingPrintData(
          rows: monthlyRows
              .map(
                (row) => AdvisorRankingPrintRow(
                  rank: row.rank,
                  fullName: row.student.name,
                  totalScore: row.totalScore,
                  averageScore: row.averageScore,
                  mention: row.mention,
                  resultStatus: row.resultStatus,
                ),
              )
              .toList(growable: false),
        ),
        title: 'តារាងចំណាត់ថ្នាក់',
        subtitle: _selectedMonthlyReportSubtitle(),
      ),
    };
  }

  Widget _buildClassAdviserScorebookView(
    GradeCalculationData data,
    List<_MonthlyAdviserRow> monthlyRows,
  ) {
    if (monthlyRows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះទេ។'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMonthlyReportHeader(
          title: 'តារាងបូងពិន្ទុប្រលងប្រចាំខែ',
          subtitle: _selectedMonthlyReportSubtitle(),
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.surfaceMuted,
                ),
                columnSpacing: 10,
                horizontalMargin: 10,
                dividerThickness: 0.8,
                border: TableBorder(
                  horizontalInside: const BorderSide(
                    color: AppColors.border,
                    width: 0.8,
                  ),
                  verticalInside: const BorderSide(
                    color: AppColors.border,
                    width: 0.8,
                  ),
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'ល.រ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'គោត្តនាម និងនាម',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...data.subjects.map(
                    (subject) => DataColumn(
                      label: Text(
                        subject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'សរុប',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'ម-ភាគ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'និទ្ទេស',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'ចំណាត់ថ្នាក់',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: monthlyRows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;

                  return DataRow(
                    color: _buildGradebookRowColor(index),
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        Text(
                          row.student.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...data.subjects.map((subject) {
                        final score =
                            row.subjectYearlyAverages[subject.id] ?? 0;
                        return DataCell(
                          Text(score > 0 ? score.toStringAsFixed(1) : '-'),
                        );
                      }),
                      DataCell(Text(row.totalScore.toStringAsFixed(1))),
                      DataCell(Text(row.averageScore.toStringAsFixed(2))),
                      DataCell(Text(row.mention)),
                      DataCell(Text(row.rank.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReportHeader({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceRaised, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: AppSizes.paddingXs),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _monthlyReportSubtitle() {
    final now = DateTime.now();
    const monthKeys = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthKey = monthKeys[now.month - 1];
    final monthLabel = kMonthLabels[monthKey] ?? monthKey;
    return 'ប្រចាំខែ $monthLabel ${now.year}';
  }

  String _selectedMonthlyReportSubtitle() {
    final year = DateTime.now().year;
    final monthLabel =
        kMonthLabels[_selectedAdviserMonth] ?? _selectedAdviserMonth;
    return 'ប្រចាំខែ $monthLabel $year';
  }

  List<_MonthlyAdviserRow> _buildMonthlyAdviserRows(GradeCalculationData data) {
    final subjectIds = data.subjects
        .map((subject) => subject.id)
        .whereType<String>()
        .toList(growable: false);
    if (subjectIds.isEmpty) {
      return const [];
    }

    final studentOrder = <String>[];
    final seenStudentIds = <String>{};
    final studentById = <String, StudentModel>{};
    final subjectScoresByStudentId = <String, Map<String, double>>{};

    for (final subject in data.subjects) {
      final subjectId = subject.id;
      if (subjectId == null) {
        continue;
      }

      final rows =
          data.subjectTeacherRows[subjectId] ?? const <SubjectTeacherRow>[];
      for (final row in rows) {
        final studentId = _monthlyStudentKey(row);
        if (seenStudentIds.add(studentId)) {
          studentOrder.add(studentId);
        }

        studentById[studentId] = row.student;
        subjectScoresByStudentId.putIfAbsent(studentId, () => {});
        subjectScoresByStudentId[studentId]![subjectId] =
            row.monthlyPercentages[_selectedAdviserMonth] ?? 0;
      }
    }

    final unrankedRows = studentOrder
        .map((studentId) {
          final student = studentById[studentId];
          if (student == null) {
            return null;
          }

          final subjectScores = {
            for (final subjectId in subjectIds)
              subjectId: subjectScoresByStudentId[studentId]?[subjectId] ?? 0,
          };
          final totalScore = subjectScores.values.fold<double>(
            0,
            (sum, value) => sum + value,
          );
          final averageScore = totalScore / subjectIds.length;

          return _MonthlyAdviserRow(
            student: student,
            subjectYearlyAverages: subjectScores,
            totalScore: totalScore,
            averageScore: averageScore,
            mention: _monthlyMention(averageScore),
          );
        })
        .whereType<_MonthlyAdviserRow>()
        .toList();

    unrankedRows.sort((a, b) {
      final totalCompare = b.totalScore.compareTo(a.totalScore);
      if (totalCompare != 0) {
        return totalCompare;
      }
      return a.student.name.compareTo(b.student.name);
    });

    var currentRank = 1;
    double? previousTotal;
    final rankedRows = <_MonthlyAdviserRow>[];
    for (var index = 0; index < unrankedRows.length; index++) {
      final row = unrankedRows[index];
      if (previousTotal != null && row.totalScore != previousTotal) {
        currentRank = index + 1;
      }
      rankedRows.add(row.copyWith(rank: currentRank));
      previousTotal = row.totalScore;
    }

    return rankedRows;
  }

  String _monthlyStudentKey(SubjectTeacherRow row) {
    final studentId = row.student.id?.trim();
    if (studentId != null && studentId.isNotEmpty) {
      return studentId;
    }
    return row.student.name.trim();
  }

  String _monthlyMention(double averageScore) {
    if (averageScore >= 40.0) {
      return 'ល្អ';
    }
    if (averageScore >= 32.5) {
      return 'ល្អបង្គួរ';
    }
    if (averageScore >= 25.0) {
      return 'មធ្យម';
    }
    return 'ខ្សោយ';
  }

  // ---------------------------------------------------------------------------
  //  Subject Teacher View
  // ---------------------------------------------------------------------------

  Widget _buildSubjectTeacherView(GradeCalculationData data) {
    if (_selectedSubjectId == null ||
        !data.subjectTeacherRows.containsKey(_selectedSubjectId)) {
      return const Center(child: Text('សូមជ្រើសមុខវិជ្ជាត្រឹមត្រូវ'));
    }

    final rows = data.subjectTeacherRows[_selectedSubjectId]!;
    if (rows.isEmpty) {
      return const Center(child: Text('មិនមានសិស្សក្នុងថ្នាក់នេះ។'));
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final sem1Sorted = rows.where((r) => r.sem1Average > 0).toList()
      ..sort((a, b) => b.sem1Average.compareTo(a.sem1Average));
    final sem2Sorted = rows.where((r) => r.sem2Average > 0).toList()
      ..sort((a, b) => b.sem2Average.compareTo(a.sem2Average));

    final sem1Ranks = <String, int>{};
    final sem2Ranks = <String, int>{};

    int currentSem1Rank = 1;
    for (int i = 0; i < sem1Sorted.length; i++) {
      if (i > 0 && sem1Sorted[i].sem1Average < sem1Sorted[i - 1].sem1Average) {
        currentSem1Rank = i + 1;
      }
      final studentId = sem1Sorted[i].student.id;
      if (studentId != null) {
        sem1Ranks[studentId] = currentSem1Rank;
      }
    }

    int currentSem2Rank = 1;
    for (int i = 0; i < sem2Sorted.length; i++) {
      if (i > 0 && sem2Sorted[i].sem2Average < sem2Sorted[i - 1].sem2Average) {
        currentSem2Rank = i + 1;
      }
      final studentId = sem2Sorted[i].student.id;
      if (studentId != null) {
        sem2Ranks[studentId] = currentSem2Rank;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          columnSpacing: 10,
          horizontalMargin: 10,
          dividerThickness: 0.8,
          border: TableBorder(
            horizontalInside: const BorderSide(
              color: AppColors.border,
              width: 0.8,
            ),
            verticalInside: const BorderSide(
              color: AppColors.border,
              width: 0.8,
            ),
          ),
          columns: [
            const DataColumn(
              label: Text('ល.រ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const DataColumn(
              label: Text(
                'នាម និង គោត្តនាម',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...months.map(
              (m) => DataColumn(
                label: Text(
                  kMonthLabels[m] ?? m,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'ឆ-ទី1',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'ចំ-ឆ1',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'ឆ-ទី2',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'ចំ-ឆ2',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          rows: rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final studentId = row.student.id;
            return DataRow(
              color: _buildGradebookRowColor(index),
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Text(
                    row.student.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                ...months.map((m) => _buildMonthCell(row, m)),
                _buildSemesterCell(
                  row,
                  'SEM1',
                  'ឆមាសទី 1',
                  row.sem1Average,
                  row.sem1OverrideEntry,
                ),
                DataCell(
                  Text(
                    studentId != null && sem1Ranks.containsKey(studentId)
                        ? sem1Ranks[studentId].toString()
                        : '-',
                  ),
                ),
                _buildSemesterCell(
                  row,
                  'SEM2',
                  'ឆមាសទី 2',
                  row.sem2Average,
                  row.sem2OverrideEntry,
                ),
                DataCell(
                  Text(
                    studentId != null && sem2Ranks.containsKey(studentId)
                        ? sem2Ranks[studentId].toString()
                        : '-',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  WidgetStateProperty<Color?> _buildGradebookRowColor(int index) {
    final baseColor = index.isEven
        ? AppColors.surfaceRaised
        : AppColors.canvasSoft.withValues(alpha: 0.72);

    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return AppColors.primarySoft.withValues(alpha: 0.5);
      }
      return baseColor;
    });
  }

  // ---------------------------------------------------------------------------
  //  Month Cell — always tappable
  // ---------------------------------------------------------------------------

  DataCell _buildMonthCell(SubjectTeacherRow row, String month) {
    final entries = row.monthlyEntries[month] ?? [];
    final raw = row.monthlyRawScores[month];

    final hasAssignments = entries.isNotEmpty;
    final hasScore = raw != null && hasAssignments;

    String displayText = '-';
    if (hasScore) {
      final totalMax = entries.fold<double>(
        0,
        (s, e) => s + e.assignment.maxPoints,
      );
      displayText = '${raw.toStringAsFixed(0)}/${totalMax.toStringAsFixed(0)}';
    }

    return DataCell(
      InkWell(
        onTap: () => _showScoreEntryDialog(row, month, entries),
        borderRadius: BorderRadius.circular(6),
        child: _scorePill(
          displayText,
          hasScore,
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Semester / Yearly Cell — tappable, supports manual override
  // ---------------------------------------------------------------------------

  DataCell _buildSemesterCell(
    SubjectTeacherRow row,
    String periodTag, // 'SEM1', 'SEM2', 'YEARLY'
    String label,
    double calculatedValue,
    AssignmentScoreEntry? overrideEntry,
  ) {
    final isOverride = overrideEntry?.currentScore != null;
    final hasValue = calculatedValue > 0;

    String displayText;
    if (isOverride) {
      final e = overrideEntry!;
      displayText =
          '${e.currentScore!.toStringAsFixed(0)}/${e.assignment.maxPoints.toStringAsFixed(0)}';
    } else if (hasValue) {
      displayText = calculatedValue.toStringAsFixed(1);
    } else {
      displayText = '-';
    }

    final accent = _semesterColor(periodTag);

    return DataCell(
      InkWell(
        onTap: () =>
            _showSemesterEntryDialog(row, periodTag, label, overrideEntry),
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _scorePill(displayText, hasValue, accent),
            // Small "auto" badge when value is calculated (not overridden)
            if (hasValue && !isOverride)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'auto',
                    style: TextStyle(
                      fontSize: 7,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _semesterColor(String tag) {
    switch (tag) {
      case 'SEM1':
        return Colors.indigo;
      case 'SEM2':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Shared pill widget used by both month and semester cells.
  Widget _scorePill(String text, bool active, Color accent) {
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? accent.withValues(alpha: 0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? accent : Colors.black45,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.edit_rounded,
            size: 10,
            color: active ? accent.withValues(alpha: 0.6) : Colors.black26,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Dialogs
  // ---------------------------------------------------------------------------

  /// Score entry dialog for monthly cells.
  Future<void> _showScoreEntryDialog(
    SubjectTeacherRow row,
    String month,
    List<AssignmentScoreEntry> entries,
  ) async {
    final subjectId = _selectedSubjectId!;
    final year = DateTime.now().year.toString();

    await showDialog(
      context: context,
      builder: (ctx) => _ScoreEntryDialog(
        studentName: row.student.name,
        titleLabel: kMonthLabels[month] ?? month,
        entries: entries,
        onSave: (Map<String, double?> newScores) async {
          final notifier = ref.read(scoreNotifierProvider.notifier);
          for (final e in newScores.entries) {
            if (e.value != null) {
              await notifier.saveScoreForAssignment(
                row.student.id!,
                e.key,
                e.value!,
              );
            }
          }
          ref.invalidate(gradeCalculationProvider(widget.classId));
        },
        onSaveFreeForm: (double score, double maxPoints, String name) async {
          final assignmentRepo = ref.read(assignmentRepositoryProvider);
          final scoreRepo = ref.read(scoreRepositoryProvider);
          final id = await assignmentRepo.insert(
            AssignmentModel(
              classId: widget.classId,
              subjectId: subjectId,
              name: name,
              month: month,
              year: year,
              maxPoints: maxPoints,
            ),
          );
          await scoreRepo.upsert(
            ScoreModel(
              studentId: row.student.id!,
              assignmentId: id,
              pointsEarned: score.clamp(0, maxPoints),
            ),
          );
          ref.invalidate(gradeCalculationProvider(widget.classId));
          ref.invalidate(assignmentNotifierProvider);
        },
      ),
    );
  }

  /// Score entry dialog for Semester / Yearly cells.
  Future<void> _showSemesterEntryDialog(
    SubjectTeacherRow row,
    String periodTag, // 'SEM1', 'SEM2', 'YEARLY'
    String label,
    AssignmentScoreEntry? existing,
  ) async {
    final subjectId = _selectedSubjectId!;
    final year = DateTime.now().year.toString();

    // Pre-build a single-entry list if an override already exists,
    // otherwise pass empty so the free-form UI shows up.
    final entries = existing != null ? [existing] : <AssignmentScoreEntry>[];

    final Map<String, String> periodNames = {
      'SEM1': 'ពិន្ទុឆមាសទី 1',
      'SEM2': 'ពិន្ទុឆមាសទី 2',
      'YEARLY': 'ពិន្ទុប្រចាំឆ្នាំ',
    };

    await showDialog(
      context: context,
      builder: (ctx) => _ScoreEntryDialog(
        studentName: row.student.name,
        titleLabel: label,
        entries: entries,
        isSemesterMode: true,
        onSave: (Map<String, double?> newScores) async {
          // Update existing override assignment score
          final notifier = ref.read(scoreNotifierProvider.notifier);
          for (final e in newScores.entries) {
            if (e.value != null) {
              await notifier.saveScoreForAssignment(
                row.student.id!,
                e.key,
                e.value!,
              );
            }
          }
          ref.invalidate(gradeCalculationProvider(widget.classId));
        },
        onSaveFreeForm: (double score, double maxPoints, String name) async {
          // Create override assignment if it doesn't exist yet
          final assignmentRepo = ref.read(assignmentRepositoryProvider);
          final scoreRepo = ref.read(scoreRepositoryProvider);
          final id = await assignmentRepo.insert(
            AssignmentModel(
              classId: widget.classId,
              subjectId: subjectId,
              name: periodNames[periodTag] ?? name,
              month: periodTag, // 'SEM1', 'SEM2', or 'YEARLY'
              year: year,
              maxPoints: maxPoints,
            ),
          );
          await scoreRepo.upsert(
            ScoreModel(
              studentId: row.student.id!,
              assignmentId: id,
              pointsEarned: score.clamp(0, maxPoints),
            ),
          );
          ref.invalidate(gradeCalculationProvider(widget.classId));
          ref.invalidate(assignmentNotifierProvider);
        },
      ),
    );
  }
}

// =============================================================================
//  Score Entry Dialog
// =============================================================================

class _MonthlyAdviserRow {
  final StudentModel student;
  final Map<String, double> subjectYearlyAverages;
  final double totalScore;
  final double averageScore;
  final String mention;
  final int rank;

  const _MonthlyAdviserRow({
    required this.student,
    required this.subjectYearlyAverages,
    required this.totalScore,
    required this.averageScore,
    required this.mention,
    this.rank = 0,
  });

  String get resultStatus => averageScore >= 25.0 ? 'ជាប់' : 'ធ្លាក់';

  _MonthlyAdviserRow copyWith({
    StudentModel? student,
    Map<String, double>? subjectYearlyAverages,
    double? totalScore,
    double? averageScore,
    String? mention,
    int? rank,
  }) {
    return _MonthlyAdviserRow(
      student: student ?? this.student,
      subjectYearlyAverages:
          subjectYearlyAverages ?? this.subjectYearlyAverages,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      mention: mention ?? this.mention,
      rank: rank ?? this.rank,
    );
  }
}

class _ScoreEntryDialog extends StatefulWidget {
  final String studentName;
  final String titleLabel;
  final List<AssignmentScoreEntry> entries;
  final bool isSemesterMode; // tweaks wording for SEM/YEARLY overrides
  final Future<void> Function(Map<String, double?> scores) onSave;
  final Future<void> Function(double score, double maxPoints, String name)
  onSaveFreeForm;

  const _ScoreEntryDialog({
    required this.studentName,
    required this.titleLabel,
    required this.entries,
    required this.onSave,
    required this.onSaveFreeForm,
    this.isSemesterMode = false,
  });

  @override
  State<_ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<_ScoreEntryDialog> {
  late Map<String, String?> _dropdownValues;
  late Map<String, TextEditingController> _controllers;

  final _freeScoreCtrl = TextEditingController();
  final _freeMaxCtrl = TextEditingController(text: '100');
  final _freeNameCtrl = TextEditingController(text: 'ពិន្ទុប្រចាំខែ');

  bool _isSaving = false;
  bool get _hasEntries => widget.entries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _dropdownValues = {};
    _controllers = {};

    for (final entry in widget.entries) {
      final id = entry.assignment.id!;
      if (entry.currentScore != null) {
        final score = entry.currentScore!;
        final presets = _buildPresets(entry.assignment.maxPoints);
        final scoreStr = _fmt(score);
        _dropdownValues[id] = presets.contains(scoreStr) ? scoreStr : 'custom';
        _controllers[id] = TextEditingController(text: scoreStr);
      } else {
        _dropdownValues[id] = 'custom';
        _controllers[id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _freeScoreCtrl.dispose();
    _freeMaxCtrl.dispose();
    _freeNameCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  List<String> _buildPresets(double maxPoints) {
    if (maxPoints <= 0) return ['0'];
    final max = maxPoints.toInt();
    final Set<int> vals = {0, max};
    for (final pct in [0.25, 0.5, 0.75]) {
      final v = (maxPoints * pct).round();
      if (v > 0 && v < max) vals.add(v);
    }
    return (vals.toList()..sort()).map((v) => v.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'បញ្ចូលពិន្ទុ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.studentName}  •  ${widget.titleLabel}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: _hasEntries
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.entries.map(_buildAssignmentRow).toList(),
                )
              : _buildFreeFormEntry(),
        ),
      ),
      actions: [
        const Divider(height: 1),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('បោះបង់'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  //  Free-form entry (no existing assignments)
  // ---------------------------------------------------------------------------

  Widget _buildFreeFormEntry() {
    final bannerText = widget.isSemesterMode
        ? 'ពិន្ទុដែលបញ្ចូលនឹងជំនួសតម្លៃដែលគណនាដោយស្វ័យប្រវត្តិ។'
        : 'ខែនេះមិនទាន់មានកិច្ចការ។ ពិន្ទុដែលបញ្ចូលនឹងបង្កើតកិច្ចការថ្មីដោយស្វ័យប្រវត្តិ។';

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Show name field only for monthly mode (sem/yearly name is fixed)
          if (!widget.isSemesterMode) ...[
            Text(
              'ឈ្មោះកិច្ចការ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _freeNameCtrl,
              decoration: InputDecoration(
                hintText: 'ពិន្ទុប្រចាំខែ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Score + Max row
          Row(
            children: [
              Expanded(
                child: _numField(
                  'ពិន្ទុដែលបាន',
                  _freeScoreCtrl,
                  autofocus: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 22, left: 10, right: 10),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 22, color: Colors.grey.shade400),
                ),
              ),
              Expanded(child: _numField('ពិន្ទុសរុប', _freeMaxCtrl)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _numField(
    String label,
    TextEditingController ctrl, {
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          autofocus: autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: '0',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  //  Existing-assignment row
  // ---------------------------------------------------------------------------

  Widget _buildAssignmentRow(AssignmentScoreEntry entry) {
    final id = entry.assignment.id!;
    final maxPts = entry.assignment.maxPoints;
    final presets = _buildPresets(maxPts);
    final isCustom = _dropdownValues[id] == 'custom';
    final maxStr = _fmt(maxPts);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.assignment.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'ពិន្ទុ: $maxStr',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _dropdownValues[id],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    isDense: true,
                  ),
                  hint: const Text('ជ្រើសរើស...'),
                  items: [
                    ...presets.map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v / $maxStr'),
                      ),
                    ),
                    const DropdownMenuItem(
                      enabled: false,
                      value: '__sep__',
                      child: Divider(height: 1),
                    ),
                    const DropdownMenuItem(
                      value: 'custom',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 14),
                          SizedBox(width: 6),
                          Text('បញ្ចូលដោយខ្លួនឯង'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null || val == '__sep__') return;
                    setState(() {
                      _dropdownValues[id] = val;
                      if (val != 'custom') _controllers[id]!.text = val;
                    });
                  },
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    controller: _controllers[id],
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: '/$maxStr',
                      suffixStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade100, height: 1),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (!_hasEntries) {
        final score = double.tryParse(_freeScoreCtrl.text.trim());
        final maxPts = double.tryParse(_freeMaxCtrl.text.trim());
        final name = _freeNameCtrl.text.trim().isEmpty
            ? 'ពិន្ទុប្រចាំខែ'
            : _freeNameCtrl.text.trim();
        if (score != null && maxPts != null && maxPts > 0) {
          // Close dialog before saving to prevent state disposal issues
          if (mounted) Navigator.of(context).pop();
          await widget.onSaveFreeForm(score, maxPts, name);
        }
      } else {
        final Map<String, double?> result = {};
        for (final entry in widget.entries) {
          final id = entry.assignment.id!;
          final maxPts = entry.assignment.maxPoints;
          final raw = _controllers[id]!.text.trim();
          if (raw.isEmpty) {
            result[id] = null;
            continue;
          }
          final parsed = double.tryParse(raw);
          result[id] = parsed?.clamp(0, maxPts).toDouble();
        }
        // Close dialog before saving to prevent state disposal issues
        if (mounted) Navigator.of(context).pop();
        await widget.onSave(result);
      }
    } catch (e) {
      // If there was an error and dialog wasn't closed, update state
      if (mounted) {
        setState(() => _isSaving = false);
      }
      rethrow;
    }
  }
}
