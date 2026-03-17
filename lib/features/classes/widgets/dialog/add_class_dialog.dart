import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

typedef AddClassSubmit =
    FutureOr<void> Function(
      String name,
      String academicYear,
      bool isAdviser,
      List<String> subjects,
    );

class AddClassDialog extends StatefulWidget {
  const AddClassDialog({super.key, required this.onSubmit});

  final AddClassSubmit onSubmit;

  static Future<void> show(BuildContext context, AddClassSubmit onSubmit) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddClassDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<AddClassDialog> createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  final Set<String> _selectedSubjects = <String>{};
  bool _isAdviser = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _yearController = TextEditingController(text: _defaultAcademicYear());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String _defaultAcademicYear() {
    final now = DateTime.now();
    final nextYear = now.year + 1;
    return '${now.year}-$nextYear';
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final year = _yearController.text.trim();
    if (name.isEmpty || year.isEmpty) {
      return;
    }

    await widget.onSubmit(
      name,
      year,
      _isAdviser,
      _selectedSubjects.toList(growable: false),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.paddingLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.createClassDialogTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createClassHelp,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.classNameLabel,
                    hintText: l10n.classNameHint,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: l10n.academicYearLabel,
                    hintText: l10n.academicYearHint,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                Text(l10n.classTypeLabel, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSizes.paddingSm),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(l10n.adviserClassLabel),
                      icon: const Icon(Icons.workspace_premium_rounded),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(l10n.standardClassLabel),
                      icon: const Icon(Icons.groups_rounded),
                    ),
                  ],
                  selected: {_isAdviser},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isAdviser = selection.first;
                    });
                  },
                ),
                if (!_isAdviser) ...[
                  const SizedBox(height: AppSizes.paddingLg),
                  Text(l10n.subjectsLabel, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSizes.paddingSm),
                  Wrap(
                    spacing: AppSizes.paddingSm,
                    runSpacing: AppSizes.paddingSm,
                    children: [
                      for (final subject in l10n.subjectCatalog)
                        FilterChip(
                          label: Text(subject),
                          selected: _selectedSubjects.contains(subject),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSubjects.add(subject);
                              } else {
                                _selectedSubjects.remove(subject);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSizes.paddingXl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: AppSizes.paddingSm),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.createClass),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
