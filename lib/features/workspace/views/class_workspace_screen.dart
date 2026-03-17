import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/excel_transfer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../assignments/providers/assignment_provider.dart';
import '../../assignments/widgets/tab/assignments_tab_widget.dart';
import '../../assignments/widgets/tab/assignments_tab_widget_with_permissions.dart';
import '../../gradebook/providers/score_provider.dart';
import '../../gradebook/services/grade_calculation_service.dart';
import '../../gradebook/views/gradebook_import_preview_screen.dart';
import '../../gradebook/views/gradebook_main_tab_widget.dart';
import '../../students/providers/student_provider.dart';
import '../../students/widgets/roster_tab_widget.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/views/subject_import_preview_screen.dart';
import '../../subjects/widgets/subjects_tab_widget.dart';

class ClassWorkspaceScreen extends ConsumerStatefulWidget {
  const ClassWorkspaceScreen({
    super.key,
    required this.classId,
    required this.className,
    this.isAdviser = false,
    this.teacherId,
  });

  final String classId;
  final String className;
  final bool isAdviser;
  final String? teacherId;

  @override
  ConsumerState<ClassWorkspaceScreen> createState() =>
      _ClassWorkspaceScreenState();
}

class _ClassWorkspaceScreenState extends ConsumerState<ClassWorkspaceScreen> {
  int _currentIndex = 0;
  final ExcelTransferService _excelTransferService = ExcelTransferService();
  final _rosterKey = GlobalKey<RosterTabWidgetState>();
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _reloadSubjects() async {
    await ref
        .read(subjectNotifierProvider.notifier)
        .loadSubjectsForClass(widget.classId, refresh: true);
  }

  Future<void> _reloadGradebookData() async {
    await Future.wait<void>([
      _reloadSubjects(),
      ref
          .read(assignmentNotifierProvider.notifier)
          .loadAssignmentsForClass(widget.classId, refresh: true),
      ref
          .read(studentNotifierProvider.notifier)
          .loadStudentsForClass(widget.classId, refresh: true),
    ]);
    ref.invalidate(scoreNotifierProvider);
    ref.invalidate(gradeCalculationProvider(widget.classId));
  }

  void _selectTab(int index) {
    if (_currentIndex == index && _loadedTabs.contains(index)) {
      return;
    }

    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return RosterTabWidget(
          key: _rosterKey,
          classId: widget.classId,
        );
      case 1:
        return SubjectsTabWidget(
          key: const PageStorageKey('subjects_tab'),
          classId: widget.classId,
        );
      case 2:
        if (widget.teacherId != null) {
          return AssignmentsTabWidgetWithPermissions(
            key: const PageStorageKey('assignments_tab_permissions'),
            classId: widget.classId,
            teacherId: widget.teacherId,
            isAdviser: widget.isAdviser,
          );
        }
        return AssignmentsTabWidget(
          key: const PageStorageKey('assignments_tab'),
          classId: widget.classId,
        );
      case 3:
        return GradebookMainTabWidget(
          key: const PageStorageKey('gradebook_tab'),
          classId: widget.classId,
          teacherId: widget.teacherId,
          isAdviser: widget.isAdviser,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleExcelAction(String action) async {
    try {
      if (action == 'subjects_sync_adviser') {
        await ref
            .read(subjectNotifierProvider.notifier)
            .syncMissingAdviserSubjects(widget.classId);
        return;
      }

      if (action == 'subjects_export') {
        await _excelTransferService.exportSubjects(
          classId: widget.classId,
          className: widget.className,
        );
        return;
      }

      if (action == 'subjects_import') {
        final preview = await _excelTransferService.previewSubjectsImport(
          classId: widget.classId,
        );

        if (!mounted) {
          return;
        }

        final count = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder: (context) => SubjectImportPreviewScreen(
              preview: preview,
              onConfirm: (rows) =>
                  _excelTransferService.importSubjectsFromPreview(
                    classId: widget.classId,
                    rows: rows,
                  ),
            ),
          ),
        );

        if (count != null && count > 0) {
          await _reloadSubjects();
        }
        return;
      }

      if (action == 'gradebook_export') {
        await _excelTransferService.exportGradebook(
          classId: widget.classId,
          className: widget.className,
        );
        return;
      }

      if (action == 'gradebook_import') {
        final preview = await _excelTransferService.previewGradebookImport(
          classId: widget.classId,
        );

        if (!mounted) {
          return;
        }

        final summary = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GradebookImportPreviewScreen(
              preview: preview,
              onConfirm: (subjects, scores) =>
                  _excelTransferService.importGradebookFromPreview(
                    classId: widget.classId,
                    subjects: subjects,
                    scores: scores,
                  ),
            ),
          ),
        );

        if (summary != null) {
          await _reloadGradebookData();
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $error')));
    }
  }

  List<Widget> _visibleActions(AppLocalizations l10n) {
    if (_currentIndex == 1) {
      return [
        if (widget.isAdviser)
          OutlinedButton.icon(
            onPressed: () => _handleExcelAction('subjects_sync_adviser'),
            icon: const Icon(Icons.sync_outlined),
            label: Text(l10n.syncAdviserSubjects),
          ),
        OutlinedButton.icon(
          onPressed: () => _handleExcelAction('subjects_export'),
          icon: const Icon(Icons.file_upload_outlined),
          label: Text(l10n.exportSubjects),
        ),
        OutlinedButton.icon(
          onPressed: () => _handleExcelAction('subjects_import'),
          icon: const Icon(Icons.file_download_outlined),
          label: Text(l10n.importSubjects),
        ),
      ];
    }

    if (_currentIndex == 3) {
      return [
        OutlinedButton.icon(
          onPressed: () => _handleExcelAction('gradebook_export'),
          icon: const Icon(Icons.file_upload_outlined),
          label: Text(l10n.exportGradebook),
        ),
        OutlinedButton.icon(
          onPressed: () => _handleExcelAction('gradebook_import'),
          icon: const Icon(Icons.file_download_outlined),
          label: Text(l10n.importGradebook),
        ),
      ];
    }

    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = AppBreakpoints.isCompact(width);
        final rail = AppBreakpoints.usesRail(width);
        final padding = AppBreakpoints.shellPadding(width);
        final actions = _visibleActions(l10n);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          floatingActionButton: compact && _currentIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      _rosterKey.currentState?.showAddStudentDialog(),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(l10n.addStudent),
                )
              : null,
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectTab,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.people_outline),
                      selectedIcon: const Icon(Icons.people),
                      label: l10n.studentsTab,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.book_outlined),
                      selectedIcon: const Icon(Icons.book),
                      label: l10n.subjectsTab,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.assignment_outlined),
                      selectedIcon: const Icon(Icons.assignment),
                      label: l10n.assignmentsTab,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.grade_outlined),
                      selectedIcon: const Icon(Icons.grade),
                      label: l10n.gradebookTab,
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  if (rail)
                    SizedBox(
                      width: 120,
                      child: TrellisSectionSurface(
                        child: NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: _selectTab,
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            NavigationRailDestination(
                              icon: const Icon(Icons.people_outline),
                              selectedIcon: const Icon(Icons.people),
                              label: Text(l10n.studentsTab),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.book_outlined),
                              selectedIcon: const Icon(Icons.book),
                              label: Text(l10n.subjectsTab),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.assignment_outlined),
                              selectedIcon: const Icon(Icons.assignment),
                              label: Text(l10n.assignmentsTab),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.grade_outlined),
                              selectedIcon: const Icon(Icons.grade),
                              label: Text(l10n.gradebookTab),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (rail) const SizedBox(width: AppSizes.paddingLg),
                  Expanded(
                    child: Column(
                      children: [
                        TrellisSectionSurface(
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const SizedBox(width: AppSizes.paddingSm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.className,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.classWorkspaceSubtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!compact && _currentIndex == 0)
                                FilledButton.icon(
                                  onPressed: () => _rosterKey.currentState
                                      ?.showAddStudentDialog(),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_outlined,
                                  ),
                                  label: Text(l10n.addStudent),
                                ),
                            ],
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingLg),
                          TrellisSectionSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.availableActions,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSizes.paddingMd),
                                TrellisCardActions(children: actions),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.paddingLg),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                            child: IndexedStack(
                              index: _currentIndex,
                              children: List<Widget>.generate(4, _buildTab),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
