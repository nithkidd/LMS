enum DashboardAlertSeverity { info, warning, critical }

class DashboardAlert {
  const DashboardAlert({
    required this.title,
    required this.message,
    required this.severity,
    this.count,
  });

  final String title;
  final String message;
  final DashboardAlertSeverity severity;
  final int? count;
}

class DashboardActionItem {
  const DashboardActionItem({
    required this.id,
    required this.title,
    required this.description,
    this.valueLabel,
    this.classId,
    this.isAdviser,
    this.schoolId,
    this.isPrimary = false,
  });

  final String id;
  final String title;
  final String description;
  final String? valueLabel;
  final String? classId;
  final bool? isAdviser;
  final String? schoolId;
  final bool isPrimary;
}

class DashboardRankingRow {
  const DashboardRankingRow({
    required this.title,
    required this.detail,
    required this.metricLabel,
    required this.score,
    this.classId,
    this.isAdviser,
    this.schoolId,
  });

  final String title;
  final String detail;
  final String metricLabel;
  final int score;
  final String? classId;
  final bool? isAdviser;
  final String? schoolId;
}

class SuperadminDashboardSummary {
  const SuperadminDashboardSummary({
    required this.organizationCount,
    required this.schoolCount,
    required this.activeAdminCount,
    required this.activeTeacherCount,
    required this.studentCount,
    required this.inactiveAccountCount,
    required this.unresolvedIssueCount,
    required this.platformAlerts,
    required this.organizationWatchlist,
    required this.accessRows,
    required this.globalTrendRows,
    required this.actionItems,
    required this.dataQualityAlerts,
    required this.scopeRows,
  });

  final int organizationCount;
  final int schoolCount;
  final int activeAdminCount;
  final int activeTeacherCount;
  final int studentCount;
  final int inactiveAccountCount;
  final int unresolvedIssueCount;
  final List<DashboardAlert> platformAlerts;
  final List<DashboardRankingRow> organizationWatchlist;
  final List<DashboardRankingRow> accessRows;
  final List<DashboardRankingRow> globalTrendRows;
  final List<DashboardActionItem> actionItems;
  final List<DashboardAlert> dataQualityAlerts;
  final List<DashboardRankingRow> scopeRows;
}

class OrganizationAdminDashboardSummary {
  const OrganizationAdminDashboardSummary({
    required this.scopeLabel,
    required this.classCount,
    required this.teacherCount,
    required this.studentCount,
    required this.adviserClassCount,
    required this.assignmentActivityCount,
    required this.attentionClassCount,
    required this.operationsAlerts,
    required this.classPriorityRows,
    required this.staffLoadRows,
    required this.rosterRows,
    required this.accessRows,
    required this.actionItems,
    required this.accessAlerts,
  });

  final String scopeLabel;
  final int classCount;
  final int teacherCount;
  final int studentCount;
  final int adviserClassCount;
  final int assignmentActivityCount;
  final int attentionClassCount;
  final List<DashboardAlert> operationsAlerts;
  final List<DashboardRankingRow> classPriorityRows;
  final List<DashboardRankingRow> staffLoadRows;
  final List<DashboardRankingRow> rosterRows;
  final List<DashboardRankingRow> accessRows;
  final List<DashboardActionItem> actionItems;
  final List<DashboardAlert> accessAlerts;
}
