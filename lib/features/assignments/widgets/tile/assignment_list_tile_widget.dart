import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/functional_minimalism_widgets.dart';
import '../../../gradebook/views/gradebook_grid_screen.dart';
import '../../data/khmer_months_list.dart';
import '../../models/assignment_model.dart';
import '../../providers/assignment_provider.dart';

class AssignmentListTileWidget extends ConsumerWidget {
  final AssignmentModel assignment;
  final VoidCallback? onDelete;

  const AssignmentListTileWidget({
    super.key,
    required this.assignment,
    this.onDelete,
  });

  void _openGradebook(BuildContext context) {
    if (assignment.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GradebookGridScreen(assignment: assignment),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: assignment.name);
    final maxPointsCtrl = TextEditingController(
      text: assignment.maxPoints.toString(),
    );
    String selectedMonth = kMonths.contains(assignment.month)
        ? assignment.month
        : kMonths.first;
    String selectedYear = assignment.year;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('កែប្រែកិច្ចការ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ឈ្មោះកិច្ចការ',
                    hintText: 'សូមបញ្ចូលឈ្មោះកិច្ចការ',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextField(
                  controller: maxPointsCtrl,
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
                        decoration: const InputDecoration(labelText: 'ឆ្នាំ'),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('បោះបង់'),
            ),
            FilledButton.icon(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final maxPoints = double.tryParse(maxPointsCtrl.text.trim());

                if (name.isNotEmpty &&
                    maxPoints != null &&
                    maxPoints > 0 &&
                    assignment.id != null) {
                  ref
                      .read(assignmentNotifierProvider.notifier)
                      .updateAssignment(
                        assignment.copyWith(
                          name: name,
                          month: selectedMonth,
                          year: selectedYear,
                          maxPoints: maxPoints,
                        ),
                      );
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('លុបកិច្ចការ'),
        content: Text(
          'តើអ្នកចង់លុប "${assignment.name}" មែនទេ? ពិន្ទុដែលទាក់ទងនឹងកិច្ចការនេះនឹងត្រូវបានលុប។',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              onDelete?.call();
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('លុបកិច្ចការ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthLabel = kMonthLabels[assignment.month] ?? assignment.month;

    return TrellisSectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(assignment.name, style: AppTextStyles.subheading),
          const SizedBox(height: AppSizes.paddingSm),
          Text(
            'ខែ $monthLabel ${assignment.year}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 4),
          Text(
            'ពិន្ទុអតិបរមា ${assignment.maxPoints}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSizes.paddingMd),
          TrellisCardActions(
            children: [
              ElevatedButton.icon(
                onPressed: () => _openGradebook(context),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('បើកតារាងពិន្ទុ'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEditDialog(context, ref),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('កែប្រែ'),
              ),
              if (onDelete != null)
                OutlinedButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.2),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('លុប'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
