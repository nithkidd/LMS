import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../subjects/providers/subject_provider.dart';
import '../providers/class_teacher_subject_provider.dart';
import '../providers/teacher_provider.dart';

class SubjectAssignmentWidget extends ConsumerStatefulWidget {
  final String classId;
  final String? schoolId;

  const SubjectAssignmentWidget({
    super.key,
    required this.classId,
    this.schoolId,
  });

  @override
  ConsumerState<SubjectAssignmentWidget> createState() =>
      _SubjectAssignmentWidgetState();
}

class _SubjectAssignmentWidgetState
    extends ConsumerState<SubjectAssignmentWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.schoolId != null) {
        ref
            .read(teacherNotifierProvider.notifier)
            .loadTeachersForSchool(widget.schoolId!);
      }
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  void _showAssignmentDialog() {
    final teachersState = ref.watch(teacherNotifierProvider);
    final subjectsState = ref.watch(subjectNotifierProvider);

    if (teachersState is! AsyncData || subjectsState is! AsyncData) {
      return;
    }

    final teachers = teachersState.value ?? [];
    final subjects = subjectsState.value ?? [];
    String? selectedTeacherId;
    String? selectedSubjectId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('ចាត់តាំងគ្រូសម្រាប់មុខវិជ្ជា'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'ជ្រើសគ្រូ',
                    ),
                    items: teachers
                        .map(
                          (teacher) => DropdownMenuItem(
                            value: teacher.id.toString(),
                            child: Text(teacher.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setStateDialog(() => selectedTeacherId = value),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'ជ្រើសមុខវិជ្ជា',
                    ),
                    items: subjects
                        .map(
                          (subject) => DropdownMenuItem(
                            value: subject.id.toString(),
                            child: Text(subject.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setStateDialog(() => selectedSubjectId = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('បោះបង់'),
              ),
              FilledButton.icon(
                onPressed:
                    selectedTeacherId != null && selectedSubjectId != null
                    ? () {
                        ref
                            .read(
                              classTeacherSubjectNotifierProvider.notifier,
                            )
                            .assignSubjectToTeacher(
                              classId: widget.classId,
                              teacherId: selectedTeacherId!,
                              subjectId: selectedSubjectId!,
                            );
                        Navigator.pop(dialogContext);
                      }
                    : null,
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('ចាត់តាំង'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog({
    required String teacherId,
    required String subjectId,
    required String teacherName,
    required String subjectName,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('លុបការចាត់តាំង'),
        content: Text(
          'តើអ្នកចង់ដក "$teacherName" ចេញពីមុខវិជ្ជា "$subjectName" មែនទេ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref
                  .read(classTeacherSubjectNotifierProvider.notifier)
                  .unassignSubjectFromTeacher(
                    classId: widget.classId,
                    teacherId: teacherId,
                    subjectId: subjectId,
                  );
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('លុបការចាត់តាំង'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(
      classSubjectTeachersProvider(widget.classId),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('ចាត់តាំងគ្រូសម្រាប់មុខវិជ្ជា')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignmentDialog,
        icon: const Icon(Icons.assignment_ind_outlined),
        label: const Text('ចាត់តាំងគ្រូ'),
      ),
      body: assignmentsState.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Text(
                  'មិនទាន់មានការចាត់តាំងគ្រូទេ។ ចុចប៊ូតុង "ចាត់តាំងគ្រូ" ដើម្បីបង្កើត។',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            itemCount: assignments.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSizes.paddingMd),
            itemBuilder: (context, index) {
              final assignment = assignments[index];

              return TrellisSectionSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.subject.name, style: AppTextStyles.subheading),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      'គ្រូដែលបានចាត់តាំង: ${assignment.teacher.name}',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    TrellisCardActions(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(
                            teacherId: assignment.teacher.id!,
                            subjectId: assignment.subject.id!,
                            teacherName: assignment.teacher.name,
                            subjectName: assignment.subject.name,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(
                              color: AppColors.danger,
                              width: 1.2,
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('លុបការចាត់តាំង'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'មានបញ្ហាពេលផ្ទុកការចាត់តាំង: $error',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
