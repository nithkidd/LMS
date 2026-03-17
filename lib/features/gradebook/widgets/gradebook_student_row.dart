import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../assignments/models/assignment_model.dart';
import '../../students/models/student_model.dart';
import '../models/score_model.dart';

class GradebookStudentRow extends StatefulWidget {
  const GradebookStudentRow({
    super.key,
    required this.student,
    required this.score,
    required this.controller,
    required this.assignment,
    required this.onSave,
    required this.focusNode,
    required this.rowNumber,
    this.onMoveNext,
  });

  final StudentModel student;
  final ScoreModel? score;
  final TextEditingController controller;
  final AssignmentModel assignment;
  final void Function(String studentId, String assignmentId, double points)
  onSave;
  final FocusNode focusNode;
  final int rowNumber;
  final VoidCallback? onMoveNext;

  @override
  State<GradebookStudentRow> createState() => _GradebookStudentRowState();
}

class _GradebookStudentRowState extends State<GradebookStudentRow> {
  Timer? _debounce;
  bool _isSaving = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant GradebookStudentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _debounce?.cancel();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }

    setState(() => _isFocused = widget.focusNode.hasFocus);
    if (!widget.focusNode.hasFocus) {
      _debounce?.cancel();
      _trySave(widget.controller.text);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (mounted) {
      setState(() {});
    }
    _debounce = Timer(const Duration(milliseconds: 420), () {
      _trySave(value);
    });
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _trySave(value);
    widget.onMoveNext?.call();
  }

  void _trySave(String value) {
    final points = _parsedValue;
    if (points == null) {
      return;
    }
    if (widget.assignment.id == null || widget.student.id == null) {
      return;
    }
    if (_matchesSavedScore(points)) {
      return;
    }

    setState(() => _isSaving = true);
    widget.onSave(widget.student.id!, widget.assignment.id!, points);

    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    });
  }

  double? get _parsedValue {
    final input = widget.controller.text.trim();
    if (input.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(input);
    if (parsed == null) {
      return null;
    }
    if (parsed < 0 || parsed > widget.assignment.maxPoints) {
      return null;
    }
    return parsed;
  }

  bool get _isInvalid {
    final input = widget.controller.text.trim();
    if (input.isEmpty) {
      return false;
    }
    final parsed = double.tryParse(input);
    if (parsed == null) {
      return true;
    }
    return parsed < 0 || parsed > widget.assignment.maxPoints;
  }

  bool _matchesSavedScore(double points) {
    final saved = widget.score?.pointsEarned;
    if (saved == null) {
      return false;
    }
    return (saved - points).abs() < 0.001;
  }

  bool get _hasSavedScore => widget.score != null;

  bool get _hasUnsavedChange {
    final input = widget.controller.text.trim();
    if (input.isEmpty) {
      return false;
    }
    final parsed = double.tryParse(input);
    if (parsed == null) {
      return false;
    }
    final saved = widget.score?.pointsEarned;
    if (saved == null) {
      return true;
    }
    return (saved - parsed).abs() >= 0.001;
  }

  _LedgerState get _ledgerState {
    if (_isInvalid) {
      return _LedgerState.invalid;
    }
    if (_isSaving) {
      return _LedgerState.saving;
    }
    if (_hasUnsavedChange) {
      return _LedgerState.unsaved;
    }
    if (_hasSavedScore) {
      return _LedgerState.saved;
    }
    return _LedgerState.empty;
  }

  @override
  Widget build(BuildContext context) {
    final accent = TrellisAccentPalette.person(
      widget.student.name,
      sex: widget.student.sex,
    );
    final remarks = widget.student.remarks?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final borderColor = switch (_ledgerState) {
          _LedgerState.saved => AppColors.success.withValues(alpha: 0.45),
          _LedgerState.saving => AppColors.primary.withValues(alpha: 0.45),
          _LedgerState.unsaved => AppColors.warning.withValues(alpha: 0.55),
          _LedgerState.invalid => AppColors.danger.withValues(alpha: 0.55),
          _LedgerState.empty =>
            _isFocused
                ? AppColors.primary.withValues(alpha: 0.55)
                : AppColors.border,
        };
        final backgroundColor = switch (_ledgerState) {
          _LedgerState.saved => AppColors.success.withValues(alpha: 0.04),
          _LedgerState.saving => AppColors.primarySoft.withValues(alpha: 0.58),
          _LedgerState.unsaved => AppColors.secondarySoft.withValues(
            alpha: 0.62,
          ),
          _LedgerState.invalid => const Color(0xFFFFF2EF),
          _LedgerState.empty => AppColors.surfaceRaised,
        };

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: borderColor, width: _isFocused ? 1.4 : 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSizes.paddingMd : AppSizes.paddingLg,
              vertical: compact ? AppSizes.paddingMd : 14,
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LedgerIdentity(
                        rowNumber: widget.rowNumber,
                        student: widget.student,
                        accent: accent,
                        remarks: remarks,
                        state: _ledgerState,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      _LedgerScoreField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        assignment: widget.assignment,
                        isFocused: _isFocused,
                        isInvalid: _isInvalid,
                        onChanged: _onChanged,
                        onSubmitted: _onSubmitted,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 86,
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.canvasSoft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '${widget.rowNumber}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: _LedgerIdentity(
                          rowNumber: widget.rowNumber,
                          student: widget.student,
                          accent: accent,
                          remarks: remarks,
                          state: _ledgerState,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingLg),
                      SizedBox(
                        width: 280,
                        child: _LedgerScoreField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          assignment: widget.assignment,
                          isFocused: _isFocused,
                          isInvalid: _isInvalid,
                          onChanged: _onChanged,
                          onSubmitted: _onSubmitted,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

enum _LedgerState { empty, unsaved, saving, saved, invalid }

class _LedgerIdentity extends StatelessWidget {
  const _LedgerIdentity({
    required this.rowNumber,
    required this.student,
    required this.accent,
    required this.remarks,
    required this.state,
  });

  final int rowNumber;
  final StudentModel student;
  final TrellisAccent accent;
  final String? remarks;
  final _LedgerState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TrellisAvatar(name: student.name, sex: student.sex, radius: 22),
        const SizedBox(width: AppSizes.paddingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: AppTextStyles.subheading),
              const SizedBox(height: 2),
              Text(
                remarks?.isNotEmpty == true ? remarks! : _stateSubtitle(state),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: _stateColor(state),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.paddingSm),
        _LedgerStateBadge(state: state, accent: accent),
      ],
    );
  }

  static String _stateSubtitle(_LedgerState state) {
    return switch (state) {
      _LedgerState.saved => 'Saved score',
      _LedgerState.saving => 'Saving score...',
      _LedgerState.unsaved => 'Pending save',
      _LedgerState.invalid => 'Enter a valid score',
      _LedgerState.empty => 'Ready for scoring',
    };
  }

  static Color _stateColor(_LedgerState state) {
    return switch (state) {
      _LedgerState.saved => AppColors.success,
      _LedgerState.saving => AppColors.primary,
      _LedgerState.unsaved => AppColors.warning,
      _LedgerState.invalid => AppColors.danger,
      _LedgerState.empty => AppColors.textSecondary,
    };
  }
}

class _LedgerScoreField extends StatelessWidget {
  const _LedgerScoreField({
    required this.controller,
    required this.focusNode,
    required this.assignment,
    required this.isFocused,
    required this.isInvalid,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AssignmentModel assignment;
  final bool isFocused;
  final bool isInvalid;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isFocused
            ? AppColors.surfaceRaised
            : AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isInvalid
              ? AppColors.danger
              : isFocused
              ? AppColors.primary
              : AppColors.borderStrong.withValues(alpha: 0.7),
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.left,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTapOutside: (_) => focusNode.unfocus(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '---',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.heading.copyWith(
                fontSize: 20,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingSm),
          Text(
            '/ ${assignment.maxPoints.toInt()}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerStateBadge extends StatelessWidget {
  const _LedgerStateBadge({required this.state, required this.accent});

  final _LedgerState state;
  final TrellisAccent accent;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      _LedgerState.saved => ('Saved', AppColors.success, Icons.check_rounded),
      _LedgerState.saving => ('Saving', AppColors.primary, Icons.more_horiz),
      _LedgerState.unsaved => (
        'Pending',
        AppColors.warning,
        Icons.schedule_rounded,
      ),
      _LedgerState.invalid => (
        'Invalid',
        AppColors.danger,
        Icons.error_outline,
      ),
      _LedgerState.empty => (
        'Ready',
        accent.foregroundColor,
        Icons.edit_note_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
