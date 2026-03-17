import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/models/app_user_profile.dart';
import '../../../core/auth/providers/auth_providers.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../classes/models/class_model.dart';
import '../../classes/widgets/dialog/add_class_dialog.dart';
import '../models/workspace_folder.dart';
import '../providers/workspace_provider.dart';
import 'class_workspace_screen.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  int _section = 0;

  double _contentMaxWidth(AppViewport viewport) {
    switch (viewport) {
      case AppViewport.compact:
        return double.infinity;
      case AppViewport.medium:
        return 1080;
      case AppViewport.expanded:
        return 1320;
      case AppViewport.large:
        return 1480;
    }
  }

  double _classCardAspectRatio(double width) {
    switch (AppBreakpoints.fromWidth(width)) {
      case AppViewport.compact:
        return 1.0;
      case AppViewport.medium:
        return 1.28;
      case AppViewport.expanded:
        return 1.34;
      case AppViewport.large:
        return 1.42;
    }
  }

  String _sectionTitle(AppLocalizations l10n) {
    switch (_section) {
      case 0:
        return l10n.workspaceTitle;
      case 1:
        return l10n.foldersSectionTitle;
      default:
        return l10n.settingsSectionTitle;
    }
  }

  String _sectionSubtitle(AppLocalizations l10n) {
    switch (_section) {
      case 0:
        return l10n.workspaceSubtitle;
      case 1:
        return l10n.foldersSectionSubtitle;
      default:
        return l10n.settingsSectionSubtitle;
    }
  }

  String _sectionEyebrow(AppLocalizations l10n) {
    switch (_section) {
      case 0:
        return l10n.overview;
      case 1:
        return l10n.folders;
      default:
        return l10n.settings;
    }
  }

  Future<void> _createClass() async {
    final l10n = AppLocalizations.of(context);
    await AddClassDialog.show(context, (name, year, isAdviser, subjects) async {
      await ref
          .read(workspaceNotifierProvider.notifier)
          .createClass(
            name: name,
            academicYear: year,
            isAdviser: isAdviser,
            subjects: subjects,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.classCreatedMessage)));
      }
    });
  }

  Future<void> _createFolder() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createFolderDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.folderNameLabel,
            hintText: l10n.folderNameHint,
          ),
          onSubmitted: (text) => Navigator.of(context).pop(text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) {
      return;
    }
    await ref.read(workspaceNotifierProvider.notifier).createFolder(value);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.folderCreatedMessage(value))));
    }
  }

  void _openClass(ClassModel classModel) {
    if (classModel.id == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassWorkspaceScreen(
          classId: classModel.id!,
          className: classModel.name,
          isAdviser: classModel.isAdviser,
        ),
      ),
    );
  }

  Future<void> _moveClass(ClassModel classModel, String? folderId) async {
    if (classModel.id == null) {
      return;
    }

    await ref
        .read(workspaceNotifierProvider.notifier)
        .assignClassToFolder(classModel.id!, folderId);

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final workspace = ref.read(workspaceNotifierProvider).asData?.value;
    final folder = folderId == null ? null : workspace?.folderById[folderId];
    final message = folder == null
        ? l10n.classUnassignedMessage(classModel.name)
        : l10n.classMovedMessage(classModel.name, folder.name);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to sign out right now: $error')),
      );
    }
  }

  Widget _buildMasthead({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool compact,
    required WorkspaceState workspace,
  }) {
    final headingStyle = compact
        ? Theme.of(context).textTheme.headlineMedium
        : AppTextStyles.display.copyWith(fontSize: 38, height: 1.04);

    final layout = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkspaceLeadBlock(
                eyebrow: _sectionEyebrow(l10n),
                title: _sectionTitle(l10n),
                subtitle: _sectionSubtitle(l10n),
                headingStyle: headingStyle,
                compact: true,
              ),
              const SizedBox(height: AppSizes.paddingLg),
              _WorkspaceActionRow(
                compact: true,
                onCreateClass: _createClass,
                onCreateFolder: _createFolder,
                createClassLabel: l10n.createClass,
                createFolderLabel: l10n.createFolder,
              ),
              const SizedBox(height: AppSizes.paddingLg),
              _WorkspaceEditorialPanel(
                compact: true,
                workspace: workspace,
                l10n: l10n,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _WorkspaceLeadBlock(
                      eyebrow: _sectionEyebrow(l10n),
                      title: _sectionTitle(l10n),
                      subtitle: _sectionSubtitle(l10n),
                      headingStyle: headingStyle,
                      compact: false,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingLg),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WorkspaceActionRow(
                          compact: false,
                          onCreateClass: _createClass,
                          onCreateFolder: _createFolder,
                          createClassLabel: l10n.createClass,
                          createFolderLabel: l10n.createFolder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingLg),
              _WorkspaceEditorialPanel(
                compact: false,
                workspace: workspace,
                l10n: l10n,
              ),
            ],
          );

    return TrellisSectionSurface(
      padding: EdgeInsets.all(
        compact ? AppSizes.paddingLg : AppSizes.paddingXl,
      ),
      backgroundColor: AppColors.surface,
      child: layout,
    );
  }

  Widget _buildSectionBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required Locale locale,
    required WorkspaceState workspace,
    required bool compact,
  }) {
    switch (_section) {
      case 0:
        return _buildOverviewSection(
          context: context,
          l10n: l10n,
          workspace: workspace,
          compact: compact,
        );
      case 1:
        return _buildFoldersSection(
          context: context,
          l10n: l10n,
          workspace: workspace,
          compact: compact,
        );
      default:
        return _buildSettingsSection(
          context: context,
          l10n: l10n,
          locale: locale,
          compact: compact,
          workspace: workspace,
        );
    }
  }

  Widget _buildOverviewSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required WorkspaceState workspace,
    required bool compact,
  }) {
    final folders = workspace.folders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrellisStaggeredReveal(
          index: 0,
          child: _WorkspaceSectionCard(
            title: l10n.classesSectionTitle,
            subtitle: l10n.classesSectionSubtitle,
            trailing: Text(
              l10n.totalClasses(workspace.classes.length),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Column(
              children: [
                if (folders.isNotEmpty) ...[
                  Wrap(
                    spacing: AppSizes.paddingSm,
                    runSpacing: AppSizes.paddingSm,
                    children: [
                      _FolderLedgerChip(
                        label: l10n.allClasses,
                        count: workspace.classes.length,
                        color: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        selected: false,
                        onTap: () {},
                      ),
                      ...folders.map(
                        (folder) => _FolderLedgerChip(
                          label: folder.name,
                          count: folder.classCount,
                          color: _colorFromHex(folder.colorHex),
                          foregroundColor: AppColors.textPrimary,
                          selected: false,
                          onTap: () {
                            ref
                                .read(workspaceNotifierProvider.notifier)
                                .selectFolder(folder.id);
                            setState(() => _section = 1);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                ],
                if (workspace.classes.isEmpty)
                  TrellisEmptyState(
                    icon: Icons.class_outlined,
                    title: l10n.noClassesTitle,
                    message: l10n.noClassesBody,
                  )
                else if (compact)
                  Column(
                    children: [
                      for (
                        var index = 0;
                        index < workspace.classes.length;
                        index++
                      ) ...[
                        Builder(
                          builder: (context) {
                            final classModel = workspace.classes[index];
                            final folder = workspace.folderForClass(
                              classModel.id,
                            );
                            return _ClassTile(
                              classModel: classModel,
                              folderName: folder?.name,
                              folders: workspace.folders
                                  .map((item) => (item.id, item.name))
                                  .toList(),
                              onOpen: () => _openClass(classModel),
                              onMove: (folderId) =>
                                  _moveClass(classModel, folderId),
                              compact: true,
                            );
                          },
                        ),
                        if (index != workspace.classes.length - 1)
                          const SizedBox(height: AppSizes.paddingMd),
                      ],
                    ],
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workspace.classes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppBreakpoints.classGridColumns(
                        MediaQuery.sizeOf(context).width,
                      ),
                      crossAxisSpacing: AppSizes.paddingMd,
                      mainAxisSpacing: AppSizes.paddingMd,
                      childAspectRatio: _classCardAspectRatio(
                        MediaQuery.sizeOf(context).width,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final classModel = workspace.classes[index];
                      final folder = workspace.folderForClass(classModel.id);
                      return _ClassTile(
                        classModel: classModel,
                        folderName: folder?.name,
                        folders: workspace.folders
                            .map((item) => (item.id, item.name))
                            .toList(),
                        onOpen: () => _openClass(classModel),
                        onMove: (folderId) => _moveClass(classModel, folderId),
                        compact: false,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoldersSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required WorkspaceState workspace,
    required bool compact,
  }) {
    final selectedFolder = workspace.selectedFolder;
    final selectedClasses = selectedFolder == null
        ? const <ClassModel>[]
        : workspace.classesForFolder(selectedFolder.id);
    final visibleFolders = selectedFolder == null
        ? workspace.folders
        : [selectedFolder];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrellisStaggeredReveal(
          index: 0,
          child: _WorkspaceSectionCard(
            title: l10n.foldersSectionTitle,
            subtitle: l10n.foldersSectionSubtitle,
            trailing: selectedFolder == null
                ? null
                : TextButton(
                    onPressed: () => ref
                        .read(workspaceNotifierProvider.notifier)
                        .selectFolder(null),
                    child: Text(l10n.allClasses),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workspace.folders.isEmpty)
                  TrellisEmptyState(
                    icon: Icons.folder_open_outlined,
                    title: l10n.noFoldersTitle,
                    message: l10n.noFoldersBody,
                  )
                else ...[
                  Wrap(
                    spacing: AppSizes.paddingSm,
                    runSpacing: AppSizes.paddingSm,
                    children: [
                      _FolderLedgerChip(
                        label: l10n.allClasses,
                        count: workspace.classes.length,
                        color: AppColors.primarySoft,
                        foregroundColor: AppColors.primary,
                        selected: selectedFolder == null,
                        onTap: () => ref
                            .read(workspaceNotifierProvider.notifier)
                            .selectFolder(null),
                      ),
                      ...workspace.folders.map(
                        (folder) => _FolderLedgerChip(
                          label: folder.name,
                          count: folder.classCount,
                          color: _colorFromHex(folder.colorHex),
                          foregroundColor: AppColors.textPrimary,
                          selected: selectedFolder?.id == folder.id,
                          onTap: () => ref
                              .read(workspaceNotifierProvider.notifier)
                              .selectFolder(folder.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleFolders.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AppBreakpoints.folderGridColumns(
                        MediaQuery.sizeOf(context).width,
                      ),
                      crossAxisSpacing: AppSizes.paddingMd,
                      mainAxisSpacing: AppSizes.paddingMd,
                      mainAxisExtent: compact ? 232 : 248,
                    ),
                    itemBuilder: (context, index) {
                      final folder = visibleFolders[index];
                      return _FolderTile(
                        folder: folder,
                        classes: workspace.classesForFolder(folder.id),
                        selected: selectedFolder?.id == folder.id,
                        l10n: l10n,
                        onTap: () => ref
                            .read(workspaceNotifierProvider.notifier)
                            .selectFolder(folder.id),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        if (selectedFolder != null) ...[
          const SizedBox(height: AppSizes.paddingLg),
          TrellisStaggeredReveal(
            index: 1,
            child: _WorkspaceSectionCard(
              title: selectedFolder.name,
              subtitle: l10n.classesInFolder(selectedFolder.classCount),
              trailing: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _colorFromHex(selectedFolder.colorHex),
                  shape: BoxShape.circle,
                ),
              ),
              child: selectedClasses.isEmpty
                  ? TrellisEmptyState(
                      icon: Icons.inbox_rounded,
                      title: l10n.noClassesTitle,
                      message: l10n.noClassesBody,
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < selectedClasses.length;
                          index++
                        ) ...[
                          _FolderClassRow(
                            classModel: selectedClasses[index],
                            onOpen: () => _openClass(selectedClasses[index]),
                          ),
                          if (index != selectedClasses.length - 1)
                            const Divider(height: AppSizes.paddingLg),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required Locale locale,
    required bool compact,
    required WorkspaceState workspace,
  }) {
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;
    final profileState = user == null
        ? const AsyncValue<AppUserProfile?>.data(null)
        : ref.watch(userProfileProvider(user.uid));

    final preferencesCard = _WorkspaceSectionCard(
      title: 'Preferences',
      subtitle: 'Language and workspace defaults',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrellisAccentIcon(
                  accent: TrellisAccentPalette.primary(
                    icon: Icons.translate_rounded,
                  ),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                const SizedBox(width: AppSizes.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.languageTitle,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.languageSubtitle, style: AppTextStyles.caption),
                      const SizedBox(height: AppSizes.paddingMd),
                      SegmentedButton<Locale>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment<Locale>(
                            value: const Locale('en'),
                            label: Text(l10n.english),
                          ),
                          ButtonSegment<Locale>(
                            value: const Locale('km'),
                            label: Text(l10n.khmer),
                          ),
                        ],
                        selected: {locale},
                        onSelectionChanged: (selection) {
                          ref
                              .read(localeControllerProvider.notifier)
                              .setLocale(selection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          const _SettingsEditorialNote(
            icon: Icons.design_services_rounded,
            title: 'Focused shell',
            body:
                'Settings stay compact so your teaching tools, class folders, and account controls remain easy to scan.',
          ),
        ],
      ),
    );

    final workspaceHealthCard = _WorkspaceSectionCard(
      title: 'Workspace health',
      subtitle: 'A quick operational snapshot of your teaching space',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.paddingMd,
            runSpacing: AppSizes.paddingMd,
            children: [
              _SettingsStatTile(
                value: '${workspace.classes.length}',
                label: 'Classes',
                detail: 'Active teaching groups',
                accent: TrellisAccentPalette.primary(icon: Icons.class_rounded),
              ),
              _SettingsStatTile(
                value: '${workspace.folders.length}',
                label: 'Folders',
                detail: 'Organized collections',
                accent: TrellisAccentPalette.warning(
                  icon: Icons.folder_rounded,
                ),
              ),
              _SettingsStatTile(
                value: '${workspace.totalStudents}',
                label: 'Students',
                detail: 'Roster footprint',
                accent: TrellisAccentPalette.success(
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMd),
          const _SettingsEditorialNote(
            icon: Icons.check_circle_outline_rounded,
            title: 'Ready for class work',
            body:
                'Your workspace is built for daily teaching operations rather than a generic admin panel.',
          ),
        ],
      ),
    );

    final accountCard = _WorkspaceSectionCard(
      title: 'Account',
      subtitle: 'Identity, scope, and authentication status',
      child: _AccountSettingsCard(
        user: user,
        profileState: profileState,
        onSignOut: _signOut,
      ),
    );

    if (compact) {
      return Column(
        children: [
          TrellisStaggeredReveal(index: 0, child: preferencesCard),
          const SizedBox(height: AppSizes.paddingLg),
          TrellisStaggeredReveal(index: 1, child: workspaceHealthCard),
          const SizedBox(height: AppSizes.paddingLg),
          TrellisStaggeredReveal(index: 2, child: accountCard),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  TrellisStaggeredReveal(index: 0, child: preferencesCard),
                  const SizedBox(height: AppSizes.paddingLg),
                  TrellisStaggeredReveal(index: 1, child: workspaceHealthCard),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.paddingLg),
            Expanded(
              flex: 6,
              child: TrellisStaggeredReveal(index: 2, child: accountCard),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final viewport = AppBreakpoints.fromWidth(width);
        final compact = AppBreakpoints.isCompact(width);
        final rail = AppBreakpoints.usesRail(width);
        final padding = AppBreakpoints.shellPadding(width);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _section,
                  onDestinationSelected: (value) =>
                      setState(() => _section = value),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.space_dashboard_outlined),
                      selectedIcon: const Icon(Icons.space_dashboard_rounded),
                      label: l10n.overview,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.folder_open_outlined),
                      selectedIcon: const Icon(Icons.folder_open_rounded),
                      label: l10n.folders,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: l10n.settings,
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rail)
                    _WorkspaceRail(
                      section: _section,
                      classesCountBuilder: () =>
                          state.asData?.value.classes.length ?? 0,
                      foldersCountBuilder: () =>
                          state.asData?.value.folders.length ?? 0,
                      onSelected: (value) => setState(() => _section = value),
                      onCreateClass: _createClass,
                      l10n: l10n,
                    ),
                  if (rail) const SizedBox(width: AppSizes.paddingLg),
                  Expanded(
                    child: state.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => TrellisEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to load workspace',
                        message: '$error',
                      ),
                      data: (workspace) {
                        return LayoutBuilder(
                          builder: (context, contentConstraints) {
                            final maxWidth = _contentMaxWidth(viewport);
                            final contentWidth = compact
                                ? contentConstraints.maxWidth
                                : contentConstraints.maxWidth < maxWidth
                                ? contentConstraints.maxWidth
                                : maxWidth;

                            return Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: contentWidth,
                                child: ListView(
                                  children: [
                                    _buildMasthead(
                                      context: context,
                                      l10n: l10n,
                                      compact: compact,
                                      workspace: workspace,
                                    ),
                                    const SizedBox(height: AppSizes.paddingLg),
                                    _buildSectionBody(
                                      context: context,
                                      l10n: l10n,
                                      locale: locale,
                                      workspace: workspace,
                                      compact: compact,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
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

class _WorkspaceRail extends StatelessWidget {
  const _WorkspaceRail({
    required this.section,
    required this.classesCountBuilder,
    required this.foldersCountBuilder,
    required this.onSelected,
    required this.onCreateClass,
    required this.l10n,
  });

  final int section;
  final int Function() classesCountBuilder;
  final int Function() foldersCountBuilder;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreateClass;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.space_dashboard_rounded,
        label: l10n.overview,
        detail: l10n.totalClasses(classesCountBuilder()),
      ),
      (
        icon: Icons.folder_open_rounded,
        label: l10n.folders,
        detail: l10n.totalFolders(foldersCountBuilder()),
      ),
      (
        icon: Icons.settings_rounded,
        label: l10n.settings,
        detail: l10n.workspaceTitle,
      ),
    ];

    return SizedBox(
      width: 212,
      child: TrellisSectionSurface(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.canvasSoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset(
                  'assets/trellis-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMd),
              Text(
                'Trellis',
                style: AppTextStyles.subheading.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.workspaceSubtitle,
                style: AppTextStyles.caption.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSizes.paddingLg),
              const Divider(),
              const SizedBox(height: AppSizes.paddingMd),
              for (var index = 0; index < items.length; index++) ...[
                _WorkspaceNavButton(
                  icon: items[index].icon,
                  label: items[index].label,
                  detail: items[index].detail,
                  selected: section == index,
                  onTap: () => onSelected(index),
                ),
                if (index != items.length - 1)
                  const SizedBox(height: AppSizes.paddingSm),
              ],
              const SizedBox(height: AppSizes.paddingLg),
              FilledButton.icon(
                onPressed: onCreateClass,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.createClass),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceLeadBlock extends StatelessWidget {
  const _WorkspaceLeadBlock({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.headingStyle,
    required this.compact,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final TextStyle? headingStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.canvasSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            eyebrow,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Text(title, style: headingStyle),
        const SizedBox(height: AppSizes.paddingSm),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: compact ? double.infinity : 740,
          ),
          child: Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceActionRow extends StatelessWidget {
  const _WorkspaceActionRow({
    required this.compact,
    required this.onCreateClass,
    required this.onCreateFolder,
    required this.createClassLabel,
    required this.createFolderLabel,
  });

  final bool compact;
  final VoidCallback onCreateClass;
  final VoidCallback onCreateFolder;
  final String createClassLabel;
  final String createFolderLabel;

  @override
  Widget build(BuildContext context) {
    final actions = [
      FilledButton.icon(
        onPressed: onCreateClass,
        icon: const Icon(Icons.add_rounded),
        label: Text(createClassLabel),
      ),
      OutlinedButton.icon(
        onPressed: onCreateFolder,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: Text(createFolderLabel),
      ),
    ];

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            actions[index],
            if (index != actions.length - 1)
              const SizedBox(height: AppSizes.paddingSm),
          ],
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSizes.paddingSm,
      runSpacing: AppSizes.paddingSm,
      children: actions,
    );
  }
}

class _WorkspaceEditorialPanel extends StatelessWidget {
  const _WorkspaceEditorialPanel({
    required this.compact,
    required this.workspace,
    required this.l10n,
  });

  final bool compact;
  final WorkspaceState workspace;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        label: l10n.totalClasses(workspace.classes.length),
        value: '${workspace.classes.length}',
        accent: TrellisAccentPalette.primary(icon: Icons.class_rounded),
      ),
      (
        label: l10n.totalFolders(workspace.folders.length),
        value: '${workspace.folders.length}',
        accent: TrellisAccentPalette.warning(icon: Icons.folder_rounded),
      ),
      (
        label: l10n.totalStudents(workspace.totalStudents),
        value: '${workspace.totalStudents}',
        accent: TrellisAccentPalette.success(icon: Icons.groups_rounded),
      ),
    ];

    final metricGrid = compact
        ? Column(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                _WorkspaceMetricCard(
                  value: metrics[index].value,
                  label: metrics[index].label,
                  accent: metrics[index].accent,
                ),
                if (index != metrics.length - 1)
                  const SizedBox(height: AppSizes.paddingSm),
              ],
            ],
          )
        : Row(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(
                  child: _WorkspaceMetricCard(
                    value: metrics[index].value,
                    label: metrics[index].label,
                    accent: metrics[index].accent,
                  ),
                ),
                if (index != metrics.length - 1)
                  const SizedBox(width: AppSizes.paddingSm),
              ],
            ],
          );

    if (compact) {
      return metricGrid;
    }

    return metricGrid;
  }
}

class _WorkspaceMetricCard extends StatelessWidget {
  const _WorkspaceMetricCard({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final TrellisAccent accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 220;

        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrellisAccentIcon(
                      accent: accent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    Text(
                      value,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 28,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                    ),
                  ],
                )
              : Row(
                  children: [
                    TrellisAccentIcon(
                      accent: accent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    const SizedBox(width: AppSizes.paddingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 28,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _WorkspaceSectionCard extends StatelessWidget {
  const _WorkspaceSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSizes.paddingMd),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSizes.paddingLg),
          child,
        ],
      ),
    );
  }
}

class _WorkspaceNavButton extends StatelessWidget {
  const _WorkspaceNavButton({
    required this.icon,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.paddingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderLedgerChip extends StatelessWidget {
  const _FolderLedgerChip({
    required this.label,
    required this.count,
    required this.color,
    required this.foregroundColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final Color foregroundColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.border,
              width: selected ? 1.3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: AppTextStyles.caption.copyWith(
                  color: foregroundColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.classes,
    required this.selected,
    required this.l10n,
    required this.onTap,
  });

  final WorkspaceFolder folder;
  final List<ClassModel> classes;
  final bool selected;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _colorFromHex(folder.colorHex);
    final preview = classes.take(3).toList(growable: false);

    return TrellisPressableScale(
      onTap: onTap,
      child: TrellisSectionSurface(
        backgroundColor: Color.lerp(tint, AppColors.white, 0.52) ?? tint,
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSm),
                Text(
                  l10n.classesInFolder(folder.classCount),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              folder.name,
              style: AppTextStyles.subheading.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Expanded(
              child: preview.isEmpty
                  ? Text(
                      l10n.noClassesBody,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final classModel in preview) ...[
                          _PreviewLine(text: classModel.name),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(selected ? l10n.viewAll : l10n.folders),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderClassRow extends StatelessWidget {
  const _FolderClassRow({required this.classModel, required this.onOpen});

  final ClassModel classModel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = TrellisAccentPalette.schoolClass(
      classModel.name,
      isAdviser: classModel.isAdviser,
    );

    return Row(
      children: [
        TrellisAccentIcon(
          accent: accent,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        const SizedBox(width: AppSizes.paddingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classModel.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${classModel.academicYear} • ${l10n.studentsInClass(classModel.totalStudents)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        TextButton(onPressed: onOpen, child: Text(l10n.openClass)),
      ],
    );
  }
}

class _SettingsMetricRow extends StatelessWidget {
  const _SettingsMetricRow({required this.label, required this.accent});

  final String label;
  final TrellisAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          TrellisAccentIcon(
            accent: accent,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsStatTile extends StatelessWidget {
  const _SettingsStatTile({
    required this.value,
    required this.label,
    required this.detail,
    required this.accent,
  });

  final String value;
  final String label;
  final String detail;
  final TrellisAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 212,
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: accent,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Text(value, style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(detail, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _SettingsEditorialNote extends StatelessWidget {
  const _SettingsEditorialNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.canvasSoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: TrellisAccentPalette.byIndex(5, icon: icon),
            size: 42,
            iconSize: 18,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSettingsCard extends StatelessWidget {
  const _AccountSettingsCard({
    required this.user,
    required this.profileState,
    required this.onSignOut,
  });

  final User? user;
  final AsyncValue<AppUserProfile?> profileState;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return profileState.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.paddingLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text(
        'Unable to load account details: $error',
        style: AppTextStyles.body.copyWith(color: AppColors.danger),
      ),
      data: (profile) {
        final scopeLabel = profile?.primaryScopeLabel;
        final displayLabel =
            profile?.displayLabel ?? user?.email ?? 'Signed-in account';
        final emailLabel =
            profile?.email ?? user?.email ?? 'No email available';
        final roleLabel = profile?.role.label ?? 'Role not assigned';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrellisAccentIcon(
                        accent: TrellisAccentPalette.primary(
                          icon: Icons.person_rounded,
                        ),
                        size: 64,
                        iconSize: 28,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      const SizedBox(width: AppSizes.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayLabel, style: AppTextStyles.heading),
                            const SizedBox(height: 6),
                            Text(
                              emailLabel,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingMd),
                            Wrap(
                              spacing: AppSizes.paddingSm,
                              runSpacing: AppSizes.paddingSm,
                              children: [
                                TrellisInfoBadge(
                                  label: roleLabel,
                                  accent: TrellisAccentPalette.warning(
                                    icon: Icons.admin_panel_settings_rounded,
                                  ),
                                ),
                                if (scopeLabel != null)
                                  TrellisInfoBadge(
                                    label: scopeLabel,
                                    accent: TrellisAccentPalette.success(
                                      icon: Icons.apartment_rounded,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compactRow = constraints.maxWidth < 720;

                      if (compactRow) {
                        return Column(
                          children: [
                            _SettingsMetricRow(
                              label: emailLabel,
                              accent: TrellisAccentPalette.byIndex(
                                2,
                                icon: Icons.alternate_email_rounded,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingMd),
                            _SettingsMetricRow(
                              label: roleLabel,
                              accent: TrellisAccentPalette.warning(
                                icon: Icons.verified_user_rounded,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SettingsMetricRow(
                              label: emailLabel,
                              accent: TrellisAccentPalette.byIndex(
                                2,
                                icon: Icons.alternate_email_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingMd),
                          Expanded(
                            child: _SettingsMetricRow(
                              label: roleLabel,
                              accent: TrellisAccentPalette.warning(
                                icon: Icons.verified_user_rounded,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            const _SettingsEditorialNote(
              icon: Icons.shield_outlined,
              title: 'Authentication session',
              body:
                  'This account view keeps identity, role, and scope together so access status is clear at a glance.',
            ),
            const SizedBox(height: AppSizes.paddingLg),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => onSignOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClassTile extends StatefulWidget {
  const _ClassTile({
    required this.classModel,
    required this.folderName,
    required this.folders,
    required this.onOpen,
    required this.onMove,
    required this.compact,
  });

  final ClassModel classModel;
  final String? folderName;
  final List<(String, String)> folders;
  final VoidCallback onOpen;
  final ValueChanged<String?> onMove;
  final bool compact;

  @override
  State<_ClassTile> createState() => _ClassTileState();
}

class _ClassTileState extends State<_ClassTile> {
  static const _cardRadius = 24.0;

  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value || widget.compact) {
      return;
    }
    setState(() => _isHovered = value);
  }

  Widget _buildAnimatedMeta({
    required Widget child,
    required ValueKey<String> key,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (animatedChild, animation) {
        final offset =
            Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: animatedChild),
        );
      },
      child: KeyedSubtree(key: key, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = TrellisAccentPalette.schoolClass(
      widget.classModel.name,
      isAdviser: widget.classModel.isAdviser,
    );

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, _isHovered ? -4.0 : 0.0, 0.0, 1.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: _isHovered
                ? AppColors.borderStrong.withValues(alpha: 0.72)
                : AppColors.border.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(
                alpha: _isHovered ? 0.08 : 0.025,
              ),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 12 : 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.backgroundColor.withValues(
                        alpha: _isHovered ? 0.98 : 0.82,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Icon(
                      accent.icon,
                      color: accent.foregroundColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.classModel.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subheading.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.classModel.academicYear,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FolderMenuButton(
                    l10n: l10n,
                    folders: widget.folders,
                    onMove: widget.onMove,
                    hasAssignedFolder: widget.folderName != null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildAnimatedMeta(
                key: ValueKey(widget.folderName ?? '__none__'),
                child: _ClassMetaLine(
                  icon: widget.folderName == null
                      ? Icons.inventory_2_outlined
                      : Icons.folder_open_rounded,
                  label: widget.folderName == null
                      ? l10n.unassignedClasses
                      : l10n.folderChip(widget.folderName!),
                  emphasized: widget.folderName != null,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _ClassMetaStat(
                    icon: Icons.groups_rounded,
                    label: l10n.studentsInClass(
                      widget.classModel.totalStudents,
                    ),
                  ),
                  _buildAnimatedMeta(
                    key: ValueKey(
                      '${widget.classModel.id}_female_${widget.classModel.femaleStudents}',
                    ),
                    child: _ClassMetaStat(
                      icon: Icons.person_rounded,
                      label:
                          '${widget.classModel.femaleStudents} ${l10n.girls}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (widget.compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _ClassOpenButton(
                        label: l10n.openClass,
                        accent: accent,
                        onPressed: widget.onOpen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RoleBadge(
                      label: widget.classModel.isAdviser
                          ? l10n.adviser
                          : l10n.standard,
                      accent: accent,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _ClassOpenButton(
                        label: l10n.openClass,
                        accent: accent,
                        onPressed: widget.onOpen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoleBadge(
                      label: widget.classModel.isAdviser
                          ? l10n.adviser
                          : l10n.standard,
                      accent: accent,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderMenuButton extends StatelessWidget {
  const _FolderMenuButton({
    required this.l10n,
    required this.folders,
    required this.onMove,
    required this.hasAssignedFolder,
  });

  final AppLocalizations l10n;
  final List<(String, String)> folders;
  final ValueChanged<String?> onMove;
  final bool hasAssignedFolder;

  @override
  Widget build(BuildContext context) {
    if (!hasAssignedFolder && folders.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      tooltip: l10n.moveToFolder,
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      onSelected: (value) => onMove(value == '__none__' ? null : value),
      itemBuilder: (context) => [
        if (hasAssignedFolder)
          PopupMenuItem(value: '__none__', child: Text(l10n.removeFromFolder)),
        ...folders.map(
          (item) => PopupMenuItem(value: item.$1, child: Text(item.$2)),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        ),
        child: const Icon(Icons.more_vert_rounded, size: 20),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.accent});

  final String label;
  final TrellisAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.backgroundColor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: accent.foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClassOpenButton extends StatelessWidget {
  const _ClassOpenButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final TrellisAccent accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent.backgroundColor.withValues(alpha: 0.92),
        foregroundColor: accent.foregroundColor,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.arrow_outward_rounded, size: 18),
      label: Text(label),
    );
  }
}

class _ClassMetaLine extends StatelessWidget {
  const _ClassMetaLine({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppColors.textPrimary : AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassMetaStat extends StatelessWidget {
  const _ClassMetaStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

Color _colorFromHex(String hex) {
  final value = hex.replaceAll('#', '').trim();
  if (value.length != 6) {
    return AppColors.primarySoft;
  }

  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) {
    return AppColors.primarySoft;
  }

  return Color(0xFF000000 | parsed);
}
