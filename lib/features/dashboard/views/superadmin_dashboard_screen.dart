import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/models/app_user_profile.dart';
import '../../../core/auth/providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../schools/models/school_model.dart';
import '../../teachers/models/teacher_model.dart';
import '../models/dashboard_summary.dart';
import '../models/superadmin_management_models.dart';
import '../providers/dashboard_providers.dart';
import '../providers/superadmin_management_providers.dart';
import 'dashboard_scaffold.dart';

class SuperadminDashboardScreen extends ConsumerWidget {
  const SuperadminDashboardScreen({super.key, required this.profile});

  final AppUserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(superadminDashboardSummaryProvider);

    return summaryState.when(
      loading: () => const DashboardStatusView(
        icon: Icons.sync_rounded,
        title: 'Loading system governance',
        message: 'Trellis is preparing the global platform dashboard.',
        loading: true,
      ),
      error: (error, _) => DashboardStatusView(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load system governance',
        message: '$error',
      ),
      data: (summary) {
        return DashboardScaffold(
          title: 'System pulse',
          subtitle:
              'Watch platform health across scope alignment, school operations, and data quality without collapsing into school-level noise.',
          scopeLabel: profile.primaryScopeLabel ?? 'Global platform access',
          navigationItems: [
            DashboardNavItemData(
              label: 'Overview',
              icon: Icons.space_dashboard_rounded,
              detail: '${summary.unresolvedIssueCount} unresolved issues',
            ),
            DashboardNavItemData(
              label: 'Organizations',
              icon: Icons.domain_rounded,
              detail: '${summary.schoolCount} schools watched',
            ),
            DashboardNavItemData(
              label: 'Access & roles',
              icon: Icons.admin_panel_settings_rounded,
              detail: '${summary.accessRows.length} role signals',
            ),
            DashboardNavItemData(
              label: 'Data quality',
              icon: Icons.fact_check_rounded,
              detail: '${summary.dataQualityAlerts.length} data alerts',
            ),
            const DashboardNavItemData(
              label: 'Settings',
              icon: Icons.settings_rounded,
              detail: 'Security and operating rules',
            ),
          ],
          statusBadges: [
            DashboardStatusBadgeData(
              label: '${summary.inactiveAccountCount} inactive accounts',
              accent: TrellisAccentPalette.warning(
                icon: Icons.lock_outline_rounded,
              ),
            ),
            DashboardStatusBadgeData(
              label: '${summary.unresolvedIssueCount} issues in queue',
              accent: TrellisAccentPalette.rose(
                icon: Icons.priority_high_rounded,
              ),
            ),
          ],
          onRefresh: () async {
            ref.invalidate(superadminDashboardSummaryProvider);
            await ref.read(superadminDashboardSummaryProvider.future);
          },
          onSignOut: () => ref.read(authServiceProvider).signOut(),
          sectionBuilder: (context, section, compact) {
            switch (section) {
              case 0:
                return _buildOverview(
                  context,
                  compact: compact,
                  summary: summary,
                  onAction: (action) => _handleAction(context, action),
                  onRowSelected: (row) => _showRow(context, row),
                );
              case 1:
                return _buildOrganizations(
                  context,
                  ref: ref,
                  compact: compact,
                  summary: summary,
                  onRowSelected: (row) => _showRow(context, row),
                );
              case 2:
                return _buildAccess(
                  context,
                  ref: ref,
                  compact: compact,
                  summary: summary,
                );
              case 3:
                return _buildDataQuality(
                  context,
                  summary: summary,
                  onRowSelected: (row) => _showRow(context, row),
                );
              default:
                return _buildSettings(
                  context,
                  compact: compact,
                  summary: summary,
                );
            }
          },
        );
      },
    );
  }

  Widget _buildOverview(
    BuildContext context, {
    required bool compact,
    required SuperadminDashboardSummary summary,
    required ValueChanged<DashboardActionItem> onAction,
    required ValueChanged<DashboardRankingRow> onRowSelected,
  }) {
    final metrics = [
      DashboardMetricData(
        label: 'Organizations',
        value: '${summary.organizationCount}',
        detail: 'Org scopes in profiles',
        accent: TrellisAccentPalette.primary(icon: Icons.domain_rounded),
      ),
      DashboardMetricData(
        label: 'Schools',
        value: '${summary.schoolCount}',
        detail: 'Local schools tracked by Trellis',
        accent: TrellisAccentPalette.byIndex(2, icon: Icons.apartment_rounded),
      ),
      DashboardMetricData(
        label: 'Active admins',
        value: '${summary.activeAdminCount}',
        detail: 'Admins with live access',
        accent: TrellisAccentPalette.warning(
          icon: Icons.manage_accounts_rounded,
        ),
      ),
      DashboardMetricData(
        label: 'Active teachers',
        value: '${summary.activeTeacherCount}',
        detail: 'Teachers with live access',
        accent: TrellisAccentPalette.success(icon: Icons.co_present_rounded),
      ),
      DashboardMetricData(
        label: 'Students',
        value: '${summary.studentCount}',
        detail: 'Total roster footprint',
        accent: TrellisAccentPalette.byIndex(5, icon: Icons.groups_rounded),
      ),
      DashboardMetricData(
        label: 'Unresolved issues',
        value: '${summary.unresolvedIssueCount}',
        detail: 'Access, data, and risk signals',
        accent: TrellisAccentPalette.rose(icon: Icons.gpp_maybe_rounded),
      ),
    ];

    return Column(
      children: [
        DashboardSectionCard(
          title: 'System pulse',
          subtitle:
              'This view is for governance: risk, drift, and unhealthy schools surface before you dive into local operations.',
          child: DashboardMetricGrid(metrics: metrics, compact: compact),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Platform health',
            subtitle:
                'Role and scope issues stay visible here because they corrupt everything below them.',
            child: DashboardAlertList(
              alerts: summary.platformAlerts,
              emptyMessage:
                  'No platform-level access issues are active right now.',
            ),
          ),
          right: DashboardSectionCard(
            title: 'Action queue',
            subtitle:
                'Use this queue to stabilize scope, account health, and school risk in order.',
            child: DashboardActionList(
              actions: summary.actionItems,
              onSelected: onAction,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Organization watchlist',
            subtitle:
                'Schools are ranked by operational and data quality pressure, not by decorative vanity metrics.',
            child: DashboardRankingList(
              rows: summary.organizationWatchlist
                  .take(5)
                  .toList(growable: false),
              emptyMessage: 'Create schools to unlock cross-school governance.',
              onSelected: onRowSelected,
            ),
          ),
          right: DashboardSectionCard(
            title: 'Global trends',
            subtitle:
                'Compact trend rows replace generic charts and keep the story operational.',
            child: DashboardRankingList(
              rows: summary.globalTrendRows,
              emptyMessage: 'No global trend rows are available yet.',
              onSelected: onRowSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizations(
    BuildContext context, {
    required WidgetRef ref,
    required bool compact,
    required SuperadminDashboardSummary summary,
    required ValueChanged<DashboardRankingRow> onRowSelected,
  }) {
    final organizationsState = ref.watch(superadminOrganizationsProvider);
    final schoolsState = ref.watch(superadminSchoolsProvider);

    return Column(
      children: [
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Organizations',
            subtitle:
                'Superadmin can create and maintain organization scopes used by admin and teacher accounts.',
            trailing: FilledButton.icon(
              onPressed: () => _showOrganizationDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add organization'),
            ),
            child: organizationsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '$error',
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
              data: (organizations) {
                if (organizations.isEmpty) {
                  return const Text(
                    'No organizations exist yet. Create one before assigning organization admins.',
                    style: AppTextStyles.body,
                  );
                }

                return Column(
                  children: [
                    for (
                      var index = 0;
                      index < organizations.length;
                      index++
                    ) ...[
                      _ManagedOrganizationTile(
                        organization: organizations[index],
                        onEdit: () => _showOrganizationDialog(
                          context,
                          ref,
                          existing: organizations[index],
                        ),
                        onDelete: () => _confirmDeleteOrganization(
                          context,
                          ref,
                          organizations[index],
                        ),
                      ),
                      if (index != organizations.length - 1)
                        const SizedBox(height: AppSizes.paddingMd),
                    ],
                  ],
                );
              },
            ),
          ),
          right: DashboardSectionCard(
            title: 'Schools',
            subtitle:
                'Manage the local school directory that teachers and operational records attach to.',
            trailing: FilledButton.icon(
              onPressed: () => _showSchoolDialog(context, ref),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Add school'),
            ),
            child: schoolsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '$error',
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
              data: (schools) {
                if (schools.isEmpty) {
                  return const Text(
                    'No schools exist yet. Create one before linking teacher records or operational classes.',
                    style: AppTextStyles.body,
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < schools.length; index++) ...[
                      _ManagedSchoolTile(
                        school: schools[index],
                        onEdit: () => _showSchoolDialog(
                          context,
                          ref,
                          existing: schools[index],
                        ),
                        onDelete: () =>
                            _confirmDeleteSchool(context, ref, schools[index]),
                      ),
                      if (index != schools.length - 1)
                        const SizedBox(height: AppSizes.paddingMd),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'School watchlist',
            subtitle:
                'Each row compresses staffing gaps, missing subjects, assignment inactivity, and scoring backlog into one drilldown target.',
            child: DashboardRankingList(
              rows: summary.organizationWatchlist,
              emptyMessage: 'No schools are available yet.',
              onSelected: onRowSelected,
            ),
          ),
          right: DashboardSectionCard(
            title: 'Scope coverage',
            subtitle:
                'These rows keep the superadmin lens global so you do not accidentally work from a school-only point of view.',
            child: DashboardRankingList(
              rows: summary.scopeRows,
              emptyMessage: 'No scope data is available yet.',
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSizes.paddingLg),
          DashboardSectionCard(
            title: 'Platform alerts',
            subtitle:
                'Identity and scope drift usually predict downstream school issues.',
            child: DashboardAlertList(
              alerts: summary.platformAlerts,
              emptyMessage: 'No platform-level alerts are active right now.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccess(
    BuildContext context, {
    required WidgetRef ref,
    required bool compact,
    required SuperadminDashboardSummary summary,
  }) {
    final adminProfilesState = ref.watch(superadminAdminProfilesProvider);
    final teacherProfilesState = ref.watch(superadminTeacherProfilesProvider);
    final teacherRecordsState = ref.watch(superadminTeachersProvider);
    final lookupsState = ref.watch(superadminDirectoryLookupsProvider);

    return Column(
      children: [
        DashboardSectionCard(
          title: 'Access control',
          subtitle:
              'Superadmin can manage platform access records here without turning this dashboard into a generic school workspace.',
          child: DashboardMetricGrid(
            compact: compact,
            metrics: [
              DashboardMetricData(
                label: 'Organizations',
                value: '${summary.organizationCount}',
                detail: 'Access scopes available',
                accent: TrellisAccentPalette.primary(
                  icon: Icons.domain_rounded,
                ),
              ),
              DashboardMetricData(
                label: 'Admin profiles',
                value: '${summary.activeAdminCount}',
                detail: 'Active org admins',
                accent: TrellisAccentPalette.warning(
                  icon: Icons.manage_accounts_rounded,
                ),
              ),
              DashboardMetricData(
                label: 'Teacher profiles',
                value: '${summary.activeTeacherCount}',
                detail: 'Active teacher records',
                accent: TrellisAccentPalette.success(icon: Icons.badge_rounded),
              ),
              DashboardMetricData(
                label: 'Inactive accounts',
                value: '${summary.inactiveAccountCount}',
                detail: 'Profiles to review',
                accent: TrellisAccentPalette.rose(
                  icon: Icons.lock_outline_rounded,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Organization admins',
            subtitle:
                'Manage scoped admin profiles that operate inside an organization boundary.',
            trailing: FilledButton.icon(
              onPressed: lookupsState.hasValue
                  ? () => _showUserProfileDialog(
                      context,
                      ref,
                      lookups: lookupsState.requireValue,
                      initialRoleValue: 'org_admin',
                    )
                  : null,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Create admin'),
            ),
            child: _buildProfileList(
              state: adminProfilesState,
              emptyMessage: 'No organization admin profiles are available yet.',
              onEdit: (profile) {
                if (!lookupsState.hasValue) return;
                _showUserProfileDialog(
                  context,
                  ref,
                  lookups: lookupsState.requireValue,
                  existing: profile,
                  initialRoleValue: 'org_admin',
                );
              },
              onDelete: (profile) =>
                  _confirmDeleteProfile(context, ref, profile),
            ),
          ),
          right: DashboardSectionCard(
            title: 'Teacher accounts',
            subtitle:
                'Manage teacher access records and keep teacher links aligned with local teacher ids.',
            trailing: FilledButton.icon(
              onPressed: lookupsState.hasValue
                  ? () => _showUserProfileDialog(
                      context,
                      ref,
                      lookups: lookupsState.requireValue,
                      initialRoleValue: 'teacher',
                    )
                  : null,
              icon: const Icon(Icons.badge_rounded),
              label: const Text('Create teacher'),
            ),
            child: _buildProfileList(
              state: teacherProfilesState,
              emptyMessage: 'No teacher profiles are available yet.',
              onEdit: (profile) {
                if (!lookupsState.hasValue) return;
                _showUserProfileDialog(
                  context,
                  ref,
                  lookups: lookupsState.requireValue,
                  existing: profile,
                  initialRoleValue: 'teacher',
                );
              },
              onDelete: (profile) =>
                  _confirmDeleteProfile(context, ref, profile),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Teacher directory',
            subtitle:
                'Maintain the local teacher records that teacher access profiles attach to.',
            trailing: FilledButton.icon(
              onPressed: lookupsState.hasValue
                  ? () => _showTeacherDirectoryDialog(
                      context,
                      ref,
                      lookups: lookupsState.requireValue,
                    )
                  : null,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add teacher'),
            ),
            child: teacherRecordsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '$error',
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
              data: (teachers) {
                if (teachers.isEmpty) {
                  return const Text(
                    'No teacher records exist yet. Add a teacher record before creating a teacher access profile.',
                    style: AppTextStyles.body,
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < teachers.length; index++) ...[
                      _ManagedTeacherTile(
                        teacher: teachers[index],
                        schoolName: _schoolNameForTeacher(
                          teachers[index],
                          lookupsState,
                        ),
                        onEdit: () {
                          if (!lookupsState.hasValue) return;
                          _showTeacherDirectoryDialog(
                            context,
                            ref,
                            lookups: lookupsState.requireValue,
                            existing: teachers[index],
                          );
                        },
                        onDelete: () => _confirmDeleteTeacherDirectory(
                          context,
                          ref,
                          teachers[index],
                        ),
                      ),
                      if (index != teachers.length - 1)
                        const SizedBox(height: AppSizes.paddingMd),
                    ],
                  ],
                );
              },
            ),
          ),
          right: DashboardSectionCard(
            title: 'Role distribution',
            subtitle:
                'Audit-oriented rows for active or inactive admin and teacher posture, plus scope repair queues.',
            child: DashboardRankingList(
              rows: summary.accessRows,
              emptyMessage: 'No access rows are available yet.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataQuality(
    BuildContext context, {
    required SuperadminDashboardSummary summary,
    required ValueChanged<DashboardRankingRow> onRowSelected,
  }) {
    return Column(
      children: [
        DashboardSectionCard(
          title: 'Data quality alerts',
          subtitle:
              'These alerts flag missing assignment movement, low score completion, and subject coverage problems.',
          child: DashboardAlertList(
            alerts: summary.dataQualityAlerts,
            emptyMessage: 'No data quality alerts are active right now.',
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        DashboardSectionCard(
          title: 'Trend board',
          subtitle:
              'A ranked list keeps the dashboard direct and avoids chart-heavy noise.',
          child: DashboardRankingList(
            rows: summary.globalTrendRows,
            emptyMessage: 'No trend rows are available right now.',
            onSelected: onRowSelected,
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(
    BuildContext context, {
    required bool compact,
    required SuperadminDashboardSummary summary,
  }) {
    return Column(
      children: [
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'System boundaries',
            subtitle:
                'Keep the superadmin surface clean by being explicit about what this screen owns.',
            child: const Column(
              children: [
                _SuperadminNotePanel(
                  title: 'Managed here',
                  body:
                      'Organizations, local schools, teacher directory records, and admin or teacher `user_profiles` documents.',
                ),
                SizedBox(height: AppSizes.paddingMd),
                _SuperadminNotePanel(
                  title: 'Still backend-owned',
                  body:
                      'Firebase Auth account creation, password delivery, and custom claims remain backend responsibilities.',
                ),
              ],
            ),
          ),
          right: DashboardSectionCard(
            title: 'Current quality queue',
            subtitle:
                'Settings still keeps live governance risk visible instead of becoming a dead-end preference page.',
            child: DashboardAlertList(
              alerts: [...summary.platformAlerts, ...summary.dataQualityAlerts],
              emptyMessage: 'No governance alerts are currently active.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileList({
    required AsyncValue<List<AppUserProfile>> state,
    required String emptyMessage,
    required ValueChanged<AppUserProfile> onEdit,
    required ValueChanged<AppUserProfile> onDelete,
  }) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(
        '$error',
        style: AppTextStyles.body.copyWith(color: AppColors.danger),
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return Text(emptyMessage, style: AppTextStyles.body);
        }

        return Column(
          children: [
            for (var index = 0; index < profiles.length; index++) ...[
              _ManagedProfileTile(
                profile: profiles[index],
                onEdit: () => onEdit(profiles[index]),
                onDelete: () => onDelete(profiles[index]),
              ),
              if (index != profiles.length - 1)
                const SizedBox(height: AppSizes.paddingMd),
            ],
          ],
        );
      },
    );
  }

  String _schoolNameForTeacher(
    TeacherModel teacher,
    AsyncValue<SuperadminDirectoryLookups> lookupsState,
  ) {
    if (!lookupsState.hasValue) {
      return 'School ${teacher.schoolId}';
    }

    for (final school in lookupsState.requireValue.schools) {
      if (school.id == teacher.schoolId) {
        return school.name;
      }
    }

    return 'School ${teacher.schoolId}';
  }

  String _schoolNameById(String schoolId, SuperadminDirectoryLookups lookups) {
    for (final school in lookups.schools) {
      if (school.id == schoolId) {
        return school.name;
      }
    }

    return 'School $schoolId';
  }

  Future<void> _showOrganizationDialog(
    BuildContext context,
    WidgetRef ref, {
    ManagedOrganization? existing,
  }) async {
    final idController = TextEditingController(text: existing?.id ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Create organization' : 'Edit organization',
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      enabled: existing == null,
                      decoration: const InputDecoration(
                        labelText: 'Organization ID',
                        hintText: 'example: org-kandal',
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        hintText: 'Kandal Organization',
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMd),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      onChanged: (value) =>
                          setStateDialog(() => isActive = value),
                      title: const Text('Active'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final id = idController.text.trim();
    final name = nameController.text.trim();
    if (id.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization ID and name are required.')),
      );
      return;
    }

    try {
      if (existing == null) {
        await ref
            .read(superadminOrganizationsProvider.notifier)
            .createOrganization(id: id, name: name);
      } else {
        await ref
            .read(superadminOrganizationsProvider.notifier)
            .updateOrganization(id: id, name: name, isActive: isActive);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save organization: $error')),
      );
    }
  }

  Future<void> _showSchoolDialog(
    BuildContext context,
    WidgetRef ref, {
    SchoolModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Create school' : 'Edit school'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'School name',
              hintText: 'Kandal Demonstration School',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (submitted != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('School name is required.')));
      return;
    }

    try {
      if (existing == null) {
        await ref
            .read(superadminSchoolsProvider.notifier)
            .createSchool(name: name);
      } else {
        await ref
            .read(superadminSchoolsProvider.notifier)
            .updateSchool(id: existing.id!, name: name);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save school: $error')));
    }
  }

  Future<void> _confirmDeleteSchool(
    BuildContext context,
    WidgetRef ref,
    SchoolModel school,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete school'),
        content: Text(
          'Delete ${school.name}? This can leave teacher profiles or class records pointing at a missing school.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(superadminSchoolsProvider.notifier)
          .deleteSchool(school.id!);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete school: $error')),
      );
    }
  }

  Future<void> _confirmDeleteOrganization(
    BuildContext context,
    WidgetRef ref,
    ManagedOrganization organization,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete organization'),
        content: Text(
          'Delete ${organization.name}? This removes the organization document but does not automatically repair scoped profiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(superadminOrganizationsProvider.notifier)
          .deleteOrganization(organization.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete organization: $error')),
      );
    }
  }

  Future<void> _showUserProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    required SuperadminDirectoryLookups lookups,
    required String initialRoleValue,
    AppUserProfile? existing,
  }) async {
    final uidController = TextEditingController(text: existing?.uid ?? '');
    final nameController = TextEditingController(
      text: existing?.displayName ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    var roleValue = existing?.role.storageValue ?? initialRoleValue;
    var isActive = existing?.isActive ?? true;
    String? organizationId = existing?.organizationId;
    String? teacherId = existing?.teacherId;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final teacherOptions = lookups.teachers;

            return AlertDialog(
              title: Text(existing == null ? 'Create profile' : 'Edit profile'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: uidController,
                        enabled: existing == null,
                        decoration: const InputDecoration(
                          labelText: 'UID / document id',
                          hintText: 'firebase auth uid',
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      DropdownButtonFormField<String>(
                        initialValue: roleValue,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                            value: 'org_admin',
                            child: Text('Organization admin'),
                          ),
                          DropdownMenuItem(
                            value: 'teacher',
                            child: Text('Teacher'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() {
                            roleValue = value;
                            if (value != 'teacher') {
                              teacherId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      DropdownButtonFormField<String>(
                        initialValue: organizationId,
                        decoration: const InputDecoration(
                          labelText: 'Organization',
                        ),
                        items: [
                          for (final organization in lookups.organizations)
                            DropdownMenuItem(
                              value: organization.id,
                              child: Text(organization.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setStateDialog(() => organizationId = value),
                      ),
                      if (roleValue == 'teacher') ...[
                        const SizedBox(height: AppSizes.paddingMd),
                        DropdownButtonFormField<String>(
                          initialValue: teacherId,
                          decoration: const InputDecoration(
                            labelText: 'Teacher record',
                          ),
                          items: [
                            for (final teacher in teacherOptions)
                              DropdownMenuItem(
                                value: teacher.id,
                                child: Text(
                                  '${teacher.name} • ${_schoolNameById(teacher.schoolId, lookups)}',
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setStateDialog(() => teacherId = value),
                        ),
                      ],
                      const SizedBox(height: AppSizes.paddingMd),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        onChanged: (value) =>
                            setStateDialog(() => isActive = value),
                        title: const Text('Active'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(existing == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final uid = uidController.text.trim();
    final email = emailController.text.trim();
    final displayName = nameController.text.trim();
    if (uid.isEmpty ||
        email.isEmpty ||
        displayName.isEmpty ||
        organizationId == null ||
        organizationId!.isEmpty ||
        (roleValue == 'teacher' && (teacherId == null || teacherId!.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'UID, display name, email, and organization are required. Teacher profiles also need a linked teacher record.',
          ),
        ),
      );
      return;
    }

    try {
      await ref
          .read(superadminUserProfilesProvider.notifier)
          .upsertUserProfile(
            ManagedUserProfileInput(
              uid: uid,
              email: email,
              displayName: displayName,
              roleValue: roleValue,
              isActive: isActive,
              organizationId: organizationId,
              teacherId: roleValue == 'teacher' ? teacherId : null,
            ),
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save profile: $error')));
    }
  }

  Future<void> _showTeacherDirectoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required SuperadminDirectoryLookups lookups,
    TeacherModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String? schoolId =
        existing?.schoolId ??
        (lookups.schools.isNotEmpty ? lookups.schools.first.id : null);

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(
              existing == null
                  ? 'Create teacher record'
                  : 'Edit teacher record',
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Teacher name',
                      hintText: 'Sok Dara',
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMd),
                  DropdownButtonFormField<String>(
                    initialValue: schoolId,
                    decoration: const InputDecoration(labelText: 'School'),
                    items: [
                      for (final school in lookups.schools)
                        DropdownMenuItem(
                          value: school.id,
                          child: Text(school.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setStateDialog(() => schoolId = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          ),
        );
      },
    );

    if (submitted != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty || schoolId == null || schoolId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher name and school are required.')),
      );
      return;
    }

    try {
      if (existing == null) {
        await ref
            .read(superadminTeachersProvider.notifier)
            .createTeacher(schoolId: schoolId!, name: name);
      } else {
        await ref
            .read(superadminTeachersProvider.notifier)
            .updateTeacher(id: existing.id!, schoolId: schoolId!, name: name);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save teacher record: $error')),
      );
    }
  }

  Future<void> _confirmDeleteTeacherDirectory(
    BuildContext context,
    WidgetRef ref,
    TeacherModel teacher,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete teacher record'),
        content: Text(
          'Delete ${teacher.name}? This can leave teacher access profiles pointing at a missing local teacher record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(superadminTeachersProvider.notifier)
          .deleteTeacher(teacher.id!);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete teacher record: $error')),
      );
    }
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    AppUserProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile'),
        content: Text(
          'Delete ${profile.displayLabel}? This removes the Trellis profile document but does not delete the Firebase Auth account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(superadminUserProfilesProvider.notifier)
          .deleteUserProfile(profile.uid);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete profile: $error')),
      );
    }
  }

  Widget _buildSplit({
    required bool compact,
    required Widget left,
    required Widget right,
  }) {
    if (compact) {
      return Column(
        children: [
          left,
          const SizedBox(height: AppSizes.paddingLg),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSizes.paddingLg),
        Expanded(child: right),
      ],
    );
  }

  void _handleAction(BuildContext context, DashboardActionItem action) {
    final message = [
      action.title,
      action.description,
      if (action.valueLabel != null) action.valueLabel!,
    ].join(' / ');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRow(BuildContext context, DashboardRankingRow row) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${row.title}: ${row.detail}')));
  }
}

class _ManagedOrganizationTile extends StatelessWidget {
  const _ManagedOrganizationTile({
    required this.organization,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedOrganization organization;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          TrellisAccentIcon(
            accent: organization.isActive
                ? TrellisAccentPalette.primary(icon: Icons.domain_rounded)
                : TrellisAccentPalette.warning(
                    icon: Icons.domain_disabled_rounded,
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
                  organization.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${organization.id} / ${organization.isActive ? 'Active' : 'Inactive'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit organization',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete organization',
          ),
        ],
      ),
    );
  }
}

class _ManagedSchoolTile extends StatelessWidget {
  const _ManagedSchoolTile({
    required this.school,
    required this.onEdit,
    required this.onDelete,
  });

  final SchoolModel school;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          TrellisAccentIcon(
            accent: TrellisAccentPalette.byIndex(
              2,
              icon: Icons.apartment_rounded,
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
                  school.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'School ID: ${school.id ?? 'Unknown'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit school',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete school',
          ),
        ],
      ),
    );
  }
}

class _ManagedProfileTile extends StatelessWidget {
  const _ManagedProfileTile({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      backgroundColor: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: profile.isActive
                ? TrellisAccentPalette.success(icon: Icons.person_rounded)
                : TrellisAccentPalette.warning(icon: Icons.person_off_rounded),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayLabel,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(profile.email, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSizes.paddingSm,
                  runSpacing: AppSizes.paddingSm,
                  children: [
                    TrellisInfoBadge(
                      label: profile.role.label,
                      accent: TrellisAccentPalette.warning(
                        icon: Icons.admin_panel_settings_rounded,
                      ),
                    ),
                    if (profile.primaryScopeLabel != null)
                      TrellisInfoBadge(
                        label: profile.primaryScopeLabel!,
                        accent: TrellisAccentPalette.primary(
                          icon: Icons.apartment_rounded,
                        ),
                      ),
                    TrellisInfoBadge(
                      label: profile.isActive ? 'Active' : 'Inactive',
                      accent: profile.isActive
                          ? TrellisAccentPalette.success(
                              icon: Icons.verified_rounded,
                            )
                          : TrellisAccentPalette.warning(
                              icon: Icons.pause_circle_outline_rounded,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete profile',
          ),
        ],
      ),
    );
  }
}

class _ManagedTeacherTile extends StatelessWidget {
  const _ManagedTeacherTile({
    required this.teacher,
    required this.schoolName,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherModel teacher;
  final String schoolName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TrellisSectionSurface(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      backgroundColor: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrellisAccentIcon(
            accent: TrellisAccentPalette.success(
              icon: Icons.co_present_rounded,
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
                  teacher.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('School: $schoolName', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                TrellisInfoBadge(
                  label: 'Teacher ID: ${teacher.id ?? 'Unknown'}',
                  accent: TrellisAccentPalette.primary(
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit teacher',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete teacher',
          ),
        ],
      ),
    );
  }
}

class _SuperadminNotePanel extends StatelessWidget {
  const _SuperadminNotePanel({required this.title, required this.body});

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
            accent: TrellisAccentPalette.byIndex(
              5,
              icon: Icons.info_outline_rounded,
            ),
            size: 40,
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
