import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/models/app_user_profile.dart';
import '../../../core/auth/providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/functional_minimalism_widgets.dart';
import '../../workspace/views/class_workspace_screen.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_scaffold.dart';

class OrganizationAdminDashboardScreen extends ConsumerWidget {
  const OrganizationAdminDashboardScreen({super.key, required this.profile});

  final AppUserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(organizationAdminDashboardSummaryProvider);

    return summaryState.when(
      loading: () => const DashboardStatusView(
        icon: Icons.sync_rounded,
        title: 'Loading organization operations',
        message: 'Trellis is preparing your organization dashboard.',
        loading: true,
      ),
      error: (error, _) => DashboardStatusView(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load organization operations',
        message: '$error',
      ),
      data: (summary) {
        return DashboardScaffold(
          title: 'Organization operations',
          subtitle:
              'Run ${summary.scopeLabel} day to day with a clear queue for staffing, assignment activity, and access setup.',
          scopeLabel: profile.primaryScopeLabel ?? summary.scopeLabel,
          navigationItems: [
            DashboardNavItemData(
              label: 'Overview',
              icon: Icons.space_dashboard_rounded,
              detail: '${summary.attentionClassCount} classes need attention',
            ),
            DashboardNavItemData(
              label: 'Classes',
              icon: Icons.class_rounded,
              detail: '${summary.classCount} classes',
            ),
            DashboardNavItemData(
              label: 'Teachers',
              icon: Icons.co_present_rounded,
              detail: '${summary.teacherCount} teachers',
            ),
            DashboardNavItemData(
              label: 'Students',
              icon: Icons.groups_rounded,
              detail: '${summary.studentCount} students',
            ),
            DashboardNavItemData(
              label: 'Access',
              icon: Icons.admin_panel_settings_rounded,
              detail: '${summary.accessAlerts.length} access alerts',
            ),
            const DashboardNavItemData(
              label: 'Settings',
              icon: Icons.settings_rounded,
              detail: 'Scope and workflow rules',
            ),
          ],
          statusBadges: [
            DashboardStatusBadgeData(
              label: '${summary.attentionClassCount} classes need focus',
              accent: TrellisAccentPalette.warning(
                icon: Icons.warning_amber_rounded,
              ),
            ),
            DashboardStatusBadgeData(
              label:
                  '${summary.assignmentActivityCount} assignments this month',
              accent: TrellisAccentPalette.success(
                icon: Icons.assignment_turned_in_rounded,
              ),
            ),
          ],
          onRefresh: () async {
            ref.invalidate(organizationAdminDashboardSummaryProvider);
            await ref.read(organizationAdminDashboardSummaryProvider.future);
          },
          onSignOut: () => ref.read(authServiceProvider).signOut(),
          sectionBuilder: (context, section, compact) {
            switch (section) {
              case 0:
                return _buildOverview(
                  context,
                  compact: compact,
                  summary: summary,
                  onAction: (action) => _handleAction(context, summary, action),
                  onClassRowSelected: (row) => _openClassFromRow(context, row),
                );
              case 1:
                return _buildClasses(
                  context,
                  compact: compact,
                  summary: summary,
                  onClassRowSelected: (row) => _openClassFromRow(context, row),
                );
              case 2:
                return _buildTeachers(context, summary: summary);
              case 3:
                return _buildStudents(
                  context,
                  summary: summary,
                  onClassRowSelected: (row) => _openClassFromRow(context, row),
                );
              case 4:
                return _buildAccess(context, summary: summary);
              default:
                return _buildSettings(context, summary: summary);
            }
          },
        );
      },
    );
  }

  Widget _buildOverview(
    BuildContext context, {
    required bool compact,
    required OrganizationAdminDashboardSummary summary,
    required ValueChanged<DashboardActionItem> onAction,
    required ValueChanged<DashboardRankingRow> onClassRowSelected,
  }) {
    final metrics = [
      DashboardMetricData(
        label: 'Classes',
        value: '${summary.classCount}',
        detail: '${summary.adviserClassCount} adviser-led',
        accent: TrellisAccentPalette.primary(icon: Icons.class_rounded),
      ),
      DashboardMetricData(
        label: 'Teachers',
        value: '${summary.teacherCount}',
        detail: 'Local staffing records',
        accent: TrellisAccentPalette.byIndex(2, icon: Icons.co_present_rounded),
      ),
      DashboardMetricData(
        label: 'Students',
        value: '${summary.studentCount}',
        detail: 'Active roster size',
        accent: TrellisAccentPalette.success(icon: Icons.groups_rounded),
      ),
      DashboardMetricData(
        label: 'Monthly activity',
        value: '${summary.assignmentActivityCount}',
        detail: 'Assignments created this month',
        accent: TrellisAccentPalette.warning(icon: Icons.assignment_rounded),
      ),
      DashboardMetricData(
        label: 'Attention classes',
        value: '${summary.attentionClassCount}',
        detail: 'Priority queue right now',
        accent: TrellisAccentPalette.rose(icon: Icons.priority_high_rounded),
      ),
    ];

    final topClasses = summary.classPriorityRows
        .take(5)
        .toList(growable: false);

    return Column(
      children: [
        DashboardSectionCard(
          title: 'Today\'s operations',
          subtitle:
              'A calm read on what needs staffing, structure, or scoring attention first.',
          child: DashboardMetricGrid(metrics: metrics, compact: compact),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Action queue',
            subtitle:
                'Start with the smallest set of actions that unblock organization operations.',
            child: DashboardActionList(
              actions: summary.actionItems,
              onSelected: onAction,
            ),
          ),
          right: DashboardSectionCard(
            title: 'Operations board',
            subtitle:
                'Concrete blockers across staffing, roster health, and assignment cadence.',
            child: DashboardAlertList(
              alerts: summary.operationsAlerts,
              emptyMessage:
                  'No urgent operational blockers are active right now.',
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        _buildSplit(
          compact: compact,
          left: DashboardSectionCard(
            title: 'Academic execution',
            subtitle: 'Classes most likely to need admin attention next.',
            child: DashboardRankingList(
              rows: topClasses,
              emptyMessage: 'No classes are available yet.',
              onSelected: onClassRowSelected,
            ),
          ),
          right: DashboardSectionCard(
            title: 'Staff load view',
            subtitle:
                'Workload signals help balance subject coverage before issues spread.',
            child: DashboardRankingList(
              rows: summary.staffLoadRows.take(5).toList(growable: false),
              emptyMessage: 'No teachers are available yet.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClasses(
    BuildContext context, {
    required bool compact,
    required OrganizationAdminDashboardSummary summary,
    required ValueChanged<DashboardRankingRow> onClassRowSelected,
  }) {
    return Column(
      children: [
        DashboardSectionCard(
          title: 'Classes needing attention',
          subtitle:
              'Ranked by missing structure, teacher coverage, monthly assignment activity, and scoring completeness.',
          trailing: TrellisInfoBadge(
            label: '${summary.attentionClassCount} active issues',
            accent: TrellisAccentPalette.warning(
              icon: Icons.rule_folder_rounded,
            ),
          ),
          child: DashboardRankingList(
            rows: summary.classPriorityRows,
            emptyMessage: 'Create classes to start organization operations.',
            onSelected: onClassRowSelected,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSizes.paddingLg),
          DashboardSectionCard(
            title: 'Operations signals',
            subtitle:
                'This view stays focused on behavior, not decorative reporting.',
            child: DashboardAlertList(
              alerts: summary.operationsAlerts,
              emptyMessage: 'Class operations are stable right now.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeachers(
    BuildContext context, {
    required OrganizationAdminDashboardSummary summary,
  }) {
    return DashboardSectionCard(
      title: 'Teacher workload',
      subtitle:
          'Use this board to spot overloading, missing coverage, and teachers who still need subject ownership.',
      child: DashboardRankingList(
        rows: summary.staffLoadRows,
        emptyMessage: 'Add teachers to unlock staffing insights.',
      ),
    );
  }

  Widget _buildStudents(
    BuildContext context, {
    required OrganizationAdminDashboardSummary summary,
    required ValueChanged<DashboardRankingRow> onClassRowSelected,
  }) {
    return DashboardSectionCard(
      title: 'Roster distribution',
      subtitle:
          'This section shows class size and roster balance so you can spot thin or empty groups quickly.',
      child: DashboardRankingList(
        rows: summary.rosterRows,
        emptyMessage: 'Students will appear once classes have rosters.',
        onSelected: onClassRowSelected,
      ),
    );
  }

  Widget _buildAccess(
    BuildContext context, {
    required OrganizationAdminDashboardSummary summary,
  }) {
    return Column(
      children: [
        DashboardSectionCard(
          title: 'Access alerts',
          subtitle:
              'Permission issues stay visible here so daily operations do not hide broken identity setup.',
          child: DashboardAlertList(
            alerts: summary.accessAlerts,
            emptyMessage: 'No scoped access issues are active right now.',
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        DashboardSectionCard(
          title: 'Scope summary',
          subtitle:
              'A compact read on who is active, inactive, or still missing proper teacher links.',
          child: DashboardRankingList(
            rows: summary.accessRows,
            emptyMessage: 'No scoped accounts are available yet.',
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(
    BuildContext context, {
    required OrganizationAdminDashboardSummary summary,
  }) {
    return Column(
      children: [
        DashboardSectionCard(
          title: 'Operational defaults',
          subtitle:
              'Organization admins stay inside local operations. Global comparisons and superadmin interventions live elsewhere.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _settingsLine('Organization scope', summary.scopeLabel),
              const SizedBox(height: AppSizes.paddingSm),
              _settingsLine(
                'Assignment tracking',
                'Monthly activity is treated as the first operational signal.',
              ),
              const SizedBox(height: AppSizes.paddingSm),
              _settingsLine(
                'Scoring backlog threshold',
                'Classes below 65% current-month scoring are flagged.',
              ),
              const SizedBox(height: AppSizes.paddingSm),
              _settingsLine(
                'Underfilled roster threshold',
                'Classes below 10 students are surfaced for review.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        DashboardSectionCard(
          title: 'Access hygiene',
          subtitle:
              'If these items start growing, resolve them before the organization data becomes confusing.',
          child: DashboardAlertList(
            alerts: summary.accessAlerts,
            emptyMessage: 'Scope and access setup are currently stable.',
          ),
        ),
      ],
    );
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

  Widget _settingsLine(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMd),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _handleAction(
    BuildContext context,
    OrganizationAdminDashboardSummary summary,
    DashboardActionItem action,
  ) {
    if (action.classId != null) {
      _openClass(
        context,
        classId: action.classId!,
        className: _resolveClassName(summary, action.classId!),
        isAdviser: action.isAdviser ?? false,
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(action.description)));
  }

  void _openClassFromRow(BuildContext context, DashboardRankingRow row) {
    final classId = row.classId;
    if (classId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(row.detail)));
      return;
    }

    _openClass(
      context,
      classId: classId,
      className: row.title,
      isAdviser: row.isAdviser ?? false,
    );
  }

  void _openClass(
    BuildContext context, {
    required String classId,
    required String className,
    required bool isAdviser,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassWorkspaceScreen(
          classId: classId,
          className: className,
          isAdviser: isAdviser,
        ),
      ),
    );
  }

  String _resolveClassName(
    OrganizationAdminDashboardSummary summary,
    String classId,
  ) {
    for (final row in summary.classPriorityRows) {
      if (row.classId == classId) {
        return row.title;
      }
    }
    for (final row in summary.rosterRows) {
      if (row.classId == classId) {
        return row.title;
      }
    }
    return 'Class';
  }
}
