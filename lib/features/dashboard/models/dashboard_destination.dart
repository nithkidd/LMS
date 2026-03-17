import '../../../core/auth/models/app_user_role.dart';

enum DashboardDestination { teacherWorkspace, organizationAdmin, superadmin }

DashboardDestination resolveDashboardFor(AppUserRole role) {
  switch (role) {
    case AppUserRole.teacher:
      return DashboardDestination.teacherWorkspace;
    case AppUserRole.organizationAdmin:
      return DashboardDestination.organizationAdmin;
    case AppUserRole.superadmin:
      return DashboardDestination.superadmin;
  }
}
