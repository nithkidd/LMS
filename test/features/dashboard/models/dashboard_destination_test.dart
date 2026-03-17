import 'package:flutter_test/flutter_test.dart';
import 'package:trellis/core/auth/models/app_user_role.dart';
import 'package:trellis/features/dashboard/models/dashboard_destination.dart';

void main() {
  group('resolveDashboardFor', () {
    test('routes teacher to workspace dashboard', () {
      expect(
        resolveDashboardFor(AppUserRole.teacher),
        DashboardDestination.teacherWorkspace,
      );
    });

    test('routes organization admin to admin dashboard', () {
      expect(
        resolveDashboardFor(AppUserRole.organizationAdmin),
        DashboardDestination.organizationAdmin,
      );
    });

    test('routes superadmin to superadmin dashboard', () {
      expect(
        resolveDashboardFor(AppUserRole.superadmin),
        DashboardDestination.superadmin,
      );
    });
  });
}
