import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../assignments/models/assignment_model.dart';
import '../../students/models/student_model.dart';
import '../../students/providers/student_provider.dart';
import '../models/score_model.dart';
import '../providers/score_provider.dart';
import '../widgets/gradebook_app_bar_bottom.dart';
import '../widgets/gradebook_student_row.dart';

class GradebookGridScreen extends ConsumerStatefulWidget {
  const GradebookGridScreen({super.key, required this.assignment});

  final AssignmentModel assignment;

  @override
  ConsumerState<GradebookGridScreen> createState() =>
      _GradebookGridScreenState();
}

class _GradebookGridScreenState extends ConsumerState<GradebookGridScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studentNotifierProvider.notifier)
          .loadStudentsForClass(widget.assignment.classId);
      ref
          .read(scoreNotifierProvider.notifier)
          .loadScoresForAssignment(widget.assignment.id!);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerForStudent(
    StudentModel student,
    ScoreModel? score,
  ) {
    final studentId = student.id!;
    final existing = _controllers[studentId];
    if (existing != null) {
      if (score != null && existing.text.trim().isEmpty) {
        existing.text = _formatPoints(score.pointsEarned);
      }
      return existing;
    }

    final controller = TextEditingController(
      text: score != null ? _formatPoints(score.pointsEarned) : '',
    );
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _controllers[studentId] = controller;
    return controller;
  }

  FocusNode _focusNodeForStudent(String studentId) {
    return _focusNodes.putIfAbsent(studentId, FocusNode.new);
  }

  void _focusNextStudent(List<StudentModel> students, int currentIndex) {
    for (var index = currentIndex + 1; index < students.length; index++) {
      final studentId = students[index].id;
      if (studentId == null) {
        continue;
      }
      final focusNode = _focusNodes[studentId];
      if (focusNode != null) {
        focusNode.requestFocus();
        return;
      }
    }
    FocusScope.of(context).unfocus();
  }

  String _formatPoints(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  double? _controllerValue(String studentId) {
    final text = _controllers[studentId]?.text.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  bool _isUnsaved(String studentId, ScoreModel? score) {
    final value = _controllerValue(studentId);
    if (value == null) {
      return false;
    }
    final saved = score?.pointsEarned;
    if (saved == null) {
      return true;
    }
    return (saved - value).abs() >= 0.001;
  }

  bool _hasValidValue(String studentId) {
    final value = _controllerValue(studentId);
    if (value == null) {
      return false;
    }
    return value >= 0 && value <= widget.assignment.maxPoints;
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentNotifierProvider);
    final scoresState = ref.watch(scoreNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.assignment.name),
            const SizedBox(height: 4),
            Text(
              '${kMonthLabels[widget.assignment.month] ?? widget.assignment.month} ${widget.assignment.year} • ${widget.assignment.maxPoints.toInt()} pts',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: studentsState.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingLg),
                child: TrellisEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No students found',
                  message:
                      'Add students to this class before entering assignment scores.',
                ),
              ),
            );
          }

          final studentScores = <String, ScoreModel>{};
          if (scoresState is AsyncData<List<ScoreModel>>) {
            for (final score in scoresState.value) {
              studentScores[score.studentId] = score;
            }
          }

          for (final student in students) {
            final studentId = student.id;
            if (studentId == null) {
              continue;
            }
            _controllerForStudent(student, studentScores[studentId]);
            _focusNodeForStudent(studentId);
          }

          var scoredCount = 0;
          var unsavedCount = 0;
          var missingCount = 0;
          for (final student in students) {
            final studentId = student.id;
            if (studentId == null) {
              continue;
            }
            final score = studentScores[studentId];
            if (_hasValidValue(studentId)) {
              scoredCount += 1;
            } else {
              missingCount += 1;
            }
            if (_isUnsaved(studentId, score)) {
              unsavedCount += 1;
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLg,
                  AppSizes.paddingMd,
                  AppSizes.paddingLg,
                  AppSizes.paddingMd,
                ),
                child: _GradebookMarkStrip(
                  assignment: widget.assignment,
                  scoredCount: scoredCount,
                  missingCount: missingCount,
                  unsavedCount: unsavedCount,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingLg,
                    0,
                    AppSizes.paddingLg,
                    AppSizes.paddingXl,
                  ),
                  itemCount: students.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSizes.paddingSm),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final studentId = student.id;
                    if (studentId == null) {
                      return const SizedBox.shrink();
                    }
                    final score = studentScores[studentId];
                    final controller = _controllers[studentId]!;
                    final focusNode = _focusNodes[studentId]!;

                    return GradebookStudentRow(
                      rowNumber: index + 1,
                      student: student,
                      score: score,
                      controller: controller,
                      assignment: widget.assignment,
                      focusNode: focusNode,
                      onMoveNext: () => _focusNextStudent(students, index),
                      onSave: (studentId, assignmentId, points) {
                        ref
                            .read(scoreNotifierProvider.notifier)
                            .saveScoreForAssignment(
                              studentId,
                              assignmentId,
                              points,
                            );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: TrellisEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load gradebook',
              message: '$e',
              accent: const TrellisAccent(
                backgroundColor: Color(0xFFFFE7E4),
                foregroundColor: AppColors.danger,
                icon: Icons.error_outline_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradebookMarkStrip extends StatelessWidget {
  const _GradebookMarkStrip({
    required this.assignment,
    required this.scoredCount,
    required this.missingCount,
    required this.unsavedCount,
  });

  final AssignmentModel assignment;
  final int scoredCount;
  final int missingCount;
  final int unsavedCount;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      backgroundColor: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final lead = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Markbook',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(assignment.name, style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'Enter scores, move row by row, and let the markbook keep your place.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          final stats = Wrap(
            spacing: AppSizes.paddingSm,
            runSpacing: AppSizes.paddingSm,
            children: [
              _GradebookStatPill(
                label: 'Scored',
                value: '$scoredCount',
                accent: TrellisAccentPalette.success(icon: Icons.check_rounded),
              ),
              _GradebookStatPill(
                label: 'Missing',
                value: '$missingCount',
                accent: TrellisAccentPalette.warning(
                  icon: Icons.pending_actions_rounded,
                ),
              ),
              _GradebookStatPill(
                label: 'Unsaved',
                value: '$unsavedCount',
                accent: unsavedCount == 0
                    ? TrellisAccentPalette.primary(
                        icon: Icons.cloud_done_rounded,
                      )
                    : TrellisAccentPalette.rose(icon: Icons.schedule_rounded),
              ),
            ],
          );

          final meta = Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.canvasSoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: AppSizes.paddingSm,
              runSpacing: AppSizes.paddingSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _GradebookMetaText(
                  label: 'Scale',
                  value: '${assignment.maxPoints.toInt()} points',
                ),
                _GradebookMetaText(
                  label: 'Period',
                  value:
                      '${kMonthLabels[assignment.month] ?? assignment.month} ${assignment.year}',
                ),
                _GradebookMetaText(label: 'Mode', value: 'Rapid entry'),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                lead,
                const SizedBox(height: AppSizes.paddingMd),
                meta,
                const SizedBox(height: AppSizes.paddingMd),
                stats,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: lead),
              const SizedBox(width: AppSizes.paddingLg),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    meta,
                    const SizedBox(height: AppSizes.paddingMd),
                    stats,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GradebookStatPill extends StatelessWidget {
  const _GradebookStatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final TrellisAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(accent.icon, size: 16, color: accent.foregroundColor),
          const SizedBox(width: 8),
          Text(
            '$label $value',
            style: AppTextStyles.caption.copyWith(
              color: accent.foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradebookMetaText extends StatelessWidget {
  const _GradebookMetaText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.caption,
        children: [
          TextSpan(
            text: '$label ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
