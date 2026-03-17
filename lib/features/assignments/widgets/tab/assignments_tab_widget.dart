import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../subjects/models/subject_model.dart';
import '../../../subjects/providers/subject_provider.dart';
import '../../data/khmer_months_list.dart';
import '../../providers/assignment_provider.dart';
import '../tile/assignment_list_tile_widget.dart';

class AssignmentsTabWidget extends ConsumerStatefulWidget {
  final String classId;

  const AssignmentsTabWidget({super.key, required this.classId});

  @override
  ConsumerState<AssignmentsTabWidget> createState() =>
      _AssignmentsTabWidgetState();
}

class _AssignmentsTabWidgetState extends ConsumerState<AssignmentsTabWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assignmentNotifierProvider.notifier)
          .loadAssignmentsForClass(widget.classId);
      ref
          .read(subjectNotifierProvider.notifier)
          .loadSubjectsForClass(widget.classId);
    });
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final maxPointsController = TextEditingController(text: '100');
    String selectedMonth = kMonths[DateTime.now().month - 1];
    String selectedYear = DateTime.now().year.toString();
    String? selectedSubjectId;

    final subjectsState = ref.watch(subjectNotifierProvider);
    List<SubjectModel> subjects = [];
    if (subjectsState is AsyncData<List<SubjectModel>>) {
      subjects = subjectsState.value;
    }

    if (subjects.isNotEmpty) {
      selectedSubjectId = subjects.first.id;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('បន្ថែមកិច្ចការ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subjects.isEmpty)
                      const Text(
                        'សូមបន្ថែមមុខវិជ្ជាជាមុនសិន មុនពេលបង្កើតកិច្ចការ។',
                        style: TextStyle(color: AppColors.danger),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'មុខវិជ្ជា',
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
                    const SizedBox(height: AppSizes.paddingMd),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ឈ្មោះកិច្ចការ',
                        hintText: 'សូមបញ្ចូលឈ្មោះកិច្ចការ',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    TextField(
                      controller: maxPointsController,
                      decoration: const InputDecoration(
                        labelText: 'ពិន្ទុអតិបរមា',
                        hintText: 'ឧទាហរណ៍ 100',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedMonth,
                            decoration: const InputDecoration(labelText: 'ខែ'),
                            items: kMonths
                                .map(
                                  (month) => DropdownMenuItem(
                                    value: month,
                                    child: Text(kMonthLabels[month] ?? month),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setStateDialog(() => selectedMonth = value!),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSm),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'ឆ្នាំ',
                            ),
                            items: ['2023', '2024', '2025', '2026']
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setStateDialog(() => selectedYear = value!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('បោះបង់'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final maxPoints = double.tryParse(
                      maxPointsController.text.trim(),
                    );

                    if (selectedSubjectId != null &&
                        name.isNotEmpty &&
                        maxPoints != null &&
                        maxPoints > 0) {
                      ref
                          .read(assignmentNotifierProvider.notifier)
                          .addAssignment(
                            widget.classId,
                            selectedSubjectId!,
                            name,
                            selectedMonth,
                            selectedYear,
                            maxPoints,
                          );
                      Navigator.of(dialogContext).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'សូមជ្រើសមុខវិជ្ជា បញ្ចូលឈ្មោះកិច្ចការ និងពិន្ទុអតិបរមាឱ្យត្រឹមត្រូវ។',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('បន្ថែមកិច្ចការ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'assignments_fab',
        onPressed: () => _showAddAssignmentDialog(context, ref),
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('បន្ថែមកិច្ចការ'),
      ),
      body: assignmentsState.when(
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Text(
                  'មិនទាន់មានកិច្ចការទេ។ ចុចប៊ូតុង "បន្ថែមកិច្ចការ" ដើម្បីបង្កើត។',
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
              return AssignmentListTileWidget(
                assignment: assignment,
                onDelete: () {
                  if (assignment.id != null) {
                    ref
                        .read(assignmentNotifierProvider.notifier)
                        .deleteAssignment(assignment.id!);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'មានបញ្ហាពេលផ្ទុកកិច្ចការ: $error',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
