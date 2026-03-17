import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../models/subject_model.dart';
import '../providers/subject_provider.dart';

class SubjectsTabWidget extends ConsumerStatefulWidget {
  final String classId;

  const SubjectsTabWidget({super.key, required this.classId});

  @override
  ConsumerState<SubjectsTabWidget> createState() => _SubjectsTabWidgetState();
}

class _SubjectsTabWidgetState extends ConsumerState<SubjectsTabWidget> {
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  Future<void> _reorderSubjects(
    List<SubjectModel> subjects,
    int oldIndex,
    int newIndex,
  ) async {
    setState(() => _isReordering = true);
    try {
      final reordered = List<SubjectModel>.from(subjects);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);

      await ref
          .read(subjectNotifierProvider.notifier)
          .reorderSubjects(widget.classId, reordered);
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('បន្ថែមមុខវិជ្ជា'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'ឈ្មោះមុខវិជ្ជា',
              hintText: 'សូមបញ្ចូលឈ្មោះមុខវិជ្ជា',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('បោះបង់'),
            ),
            FilledButton.icon(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                ref
                    .read(subjectNotifierProvider.notifier)
                    .addSubject(widget.classId, name);
                Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('បន្ថែមមុខវិជ្ជា'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSubjectDialog(BuildContext context, SubjectModel subject) {
    final nameController = TextEditingController(text: subject.name);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('កែប្រែមុខវិជ្ជា'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'ឈ្មោះមុខវិជ្ជា',
              hintText: 'សូមបញ្ចូលឈ្មោះមុខវិជ្ជា',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('បោះបង់'),
            ),
            if (subject.id != null)
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await _showDeleteDialog(context, subject);
                  if (confirmed != true) return;
                  if (!context.mounted) return;

                  ref
                      .read(subjectNotifierProvider.notifier)
                      .deleteSubject(subject.id!, widget.classId);
                  Navigator.of(dialogContext).pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('លុប'),
              ),
            FilledButton.icon(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty || subject.id == null) return;

                ref
                    .read(subjectNotifierProvider.notifier)
                    .updateSubject(subject.copyWith(name: name));
                Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('រក្សាទុក'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, SubjectModel subject) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('លុបមុខវិជ្ជា'),
        content: Text('តើអ្នកចង់លុប "${subject.name}" មែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('លុប'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subjects_fab',
        onPressed: () => _showAddSubjectDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('បន្ថែមមុខវិជ្ជា'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: subjectsState.when(
          data: (subjects) => _SubjectsContent(
            key: ValueKey('subjects_${subjects.length}_$_isReordering'),
            subjects: subjects,
            isReordering: _isReordering,
            onSubjectTap: (subject) => _showEditSubjectDialog(context, subject),
            onSubjectEdit: (subject) =>
                _showEditSubjectDialog(context, subject),
            onReorder: (oldIndex, newIndex) =>
                _reorderSubjects(subjects, oldIndex, newIndex),
          ),
          loading: () => const _SubjectsLoadingState(key: ValueKey('loading')),
          error: (error, stack) => _SubjectsStateCard(
            key: const ValueKey('error'),
            icon: Icons.error_outline_rounded,
            title: 'មានបញ្ហាក្នុងការផ្ទុកមុខវិជ្ជា',
            message: '$error',
            iconColor: AppColors.danger,
          ),
        ),
      ),
    );
  }
}

class _SubjectsContent extends StatelessWidget {
  final List<SubjectModel> subjects;
  final bool isReordering;
  final ValueChanged<SubjectModel> onSubjectTap;
  final ValueChanged<SubjectModel> onSubjectEdit;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _SubjectsContent({
    super.key,
    required this.subjects,
    required this.isReordering,
    required this.onSubjectTap,
    required this.onSubjectEdit,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: subjects.isEmpty
          ? ListView(
              key: const ValueKey('empty'),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMd,
                AppSizes.paddingSm,
                AppSizes.paddingMd,
                AppSizes.paddingXl + 88,
              ),
              children: const [
                _SubjectsOverviewHeader(subjectCount: 0, isReordering: false),
                SizedBox(height: AppSizes.paddingMd),
                _SubjectsStateCard(
                  icon: Icons.menu_book_outlined,
                  title: 'No subjects yet',
                  message:
                      'Tap "Add Subject" to build the subject list for this class.',
                ),
              ],
            )
          : ReorderableListView.builder(
              key: const ValueKey('subject_list'),
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMd,
                  AppSizes.paddingSm,
                  AppSizes.paddingMd,
                  AppSizes.paddingMd,
                ),
                child: _SubjectsOverviewHeader(
                  subjectCount: subjects.length,
                  isReordering: isReordering,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingMd,
                0,
                AppSizes.paddingMd,
                AppSizes.paddingXl + 88,
              ),
              itemCount: subjects.length,
              onReorder: onReorder,
              itemBuilder: (context, index) {
                final subject = subjects[index];

                return Padding(
                  key: ValueKey(subject.id ?? '${subject.name}_$index'),
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
                  child: TrellisStaggeredReveal(
                    index: index,
                    child: _SubjectCard(
                      subject: subject,
                      index: index,
                      onTap: () => onSubjectTap(subject),
                      onEdit: () => onSubjectEdit(subject),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SubjectsOverviewHeader extends StatelessWidget {
  const _SubjectsOverviewHeader({
    required this.subjectCount,
    required this.isReordering,
  });

  final int subjectCount;
  final bool isReordering;

  @override
  Widget build(BuildContext context) {
    final accent = TrellisAccentPalette.bySeed(
      'subjects_header',
      fallbackIcon: Icons.menu_book_rounded,
    );

    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      backgroundColor:
          Color.lerp(
            Theme.of(context).colorScheme.secondary,
            Colors.white,
            0.72,
          ) ??
          AppColors.surfaceRaised,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: accent,
            size: 48,
            iconSize: 24,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subjects $subjectCount',
                  style: AppTextStyles.subheading.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Text(
                    isReordering
                        ? 'Saving subject order...'
                        : 'Edit a subject or drag to change the display order.',
                    key: ValueKey(isReordering),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$subjectCount',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SubjectCard({
    required this.subject,
    required this.index,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = TrellisAccentPalette.subject(subject.name, index: index);

    return TrellisPressableScale(
      onTap: onTap,
      child: TrellisSectionSurface(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrellisAccentIcon(accent: accent, size: 56, iconSize: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject.name, style: AppTextStyles.subheading),
                      const SizedBox(height: 6),
                      Text(
                        'មុខវិជ្ជាទី ${index + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSm),
                TrellisSoftIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'កែប្រែមុខវិជ្ជា',
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              'ប៉ះលើកាតនេះ ដើម្បីកែប្រែឈ្មោះមុខវិជ្ជា។ ប្រើចំណុចអូសខាងស្តាំ ដើម្បីប្តូរលំដាប់បង្ហាញ។',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                TrellisInfoBadge(
                  label: 'រៀបលំដាប់បាន',
                  accent: accent,
                  icon: Icons.bookmark_rounded,
                ),
                const Spacer(),
                ReorderableDragStartListener(
                  index: index,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'អូស',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectsLoadingState extends StatelessWidget {
  const _SubjectsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      children: const [
        _SubjectLoadingCard(height: 164),
        SizedBox(height: AppSizes.paddingMd),
        _SubjectLoadingCard(height: 152),
        SizedBox(height: AppSizes.paddingMd),
        _SubjectLoadingCard(height: 152),
      ],
    );
  }
}

class _SubjectLoadingCard extends StatelessWidget {
  final double height;

  const _SubjectLoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 920),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: TrellisSectionSurface(child: SizedBox(height: height)),
    );
  }
}

class _SubjectsStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;

  const _SubjectsStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;

    return TrellisEmptyState(
      icon: icon,
      title: title,
      message: message,
      accent: TrellisAccent(
        backgroundColor: resolvedIconColor.withValues(alpha: 0.12),
        foregroundColor: resolvedIconColor,
        icon: icon,
      ),
    );
  }
}
