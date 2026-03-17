import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../views/student_details_screen.dart';
import '../views/student_profile_screen.dart';
import 'student_form_dialog.dart';

class StudentListTileWidget extends ConsumerWidget {
  final StudentModel student;
  final VoidCallback? onDelete;

  const StudentListTileWidget({
    super.key,
    required this.student,
    this.onDelete,
  });

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          StudentFormDialog(student: student, classId: student.classId),
    );

    if (result != null && student.id != null) {
      ref
          .read(studentNotifierProvider.notifier)
          .updateStudent(
            student.copyWith(
              name: result['name'] as String,
              sex: result['sex'] as String?,
              dateOfBirth: result['dateOfBirth'] as String?,
              address: result['address'] as String?,
              remarks: result['remarks'] as String?,
            ),
          );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('លុបសិស្ស'),
        content: Text('តើអ្នកចង់លុប "${student.name}" ចេញពីថ្នាក់នេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              onDelete?.call();
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('លុបសិស្ស'),
          ),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    if (student.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileScreen(
          studentId: student.id!,
          studentName: student.name,
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    if (student.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(student: student),
      ),
    );
  }

  String _buildStudentSummary() {
    final parts = <String>[];
    if ((student.sex ?? '').isNotEmpty) {
      parts.add('ភេទ ${student.sex}');
    }
    if ((student.dateOfBirth ?? '').isNotEmpty) {
      parts.add('ថ្ងៃខែឆ្នាំកំណើត ${student.dateOfBirth}');
    }
    return parts.isEmpty
        ? 'ចុចប៊ូតុងខាងក្រោមដើម្បីមើលព័ត៌មានបន្ថែម។'
        : parts.join(' • ');
  }

  String _studentBadgeLabel() {
    switch ((student.sex ?? '').toUpperCase()) {
      case 'F':
        return 'សិស្សស្រី';
      case 'M':
        return 'សិស្សប្រុស';
      default:
        return 'សិស្ស';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = TrellisAccentPalette.person(student.name, sex: student.sex);

    return TrellisSectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrellisAvatar(name: student.name, sex: student.sex, radius: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: AppTextStyles.subheading),
                    const SizedBox(height: 6),
                    Text(
                      _buildStudentSummary(),
                      style: AppTextStyles.caption.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TrellisInfoBadge(
                label: _studentBadgeLabel(),
                accent: accent,
                icon: Icons.person_rounded,
              ),
              if ((student.dateOfBirth ?? '').isNotEmpty)
                TrellisInfoBadge(
                  label: student.dateOfBirth!,
                  accent: TrellisAccentPalette.bySeed(
                    student.dateOfBirth!,
                    fallbackIcon: Icons.cake_rounded,
                  ),
                  icon: Icons.cake_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMd),
          TrellisCardActions(
            children: [
              ElevatedButton.icon(
                onPressed: () => _openDetails(context),
                icon: const Icon(Icons.person_outline),
                label: const Text('មើលព័ត៌មាន'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openProfile(context),
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('មើលពិន្ទុ'),
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
