import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/models/app_user_role.dart';
import '../../../core/auth/providers/auth_providers.dart';
import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final superadminDashboardSummaryProvider =
    FutureProvider<SuperadminDashboardSummary>((ref) async {
      final session = await ref.watch(currentAppSessionProvider.future);
      if (session == null || session.profile.role != AppUserRole.superadmin) {
        throw StateError(
          'Superadmin dashboard requested without superadmin access.',
        );
      }

      return ref
          .read(dashboardRepositoryProvider)
          .loadSuperadminSummary(session.profile);
    });

final organizationAdminDashboardSummaryProvider =
    FutureProvider<OrganizationAdminDashboardSummary>((ref) async {
      final session = await ref.watch(currentAppSessionProvider.future);
      if (session == null ||
          session.profile.role != AppUserRole.organizationAdmin) {
        throw StateError(
          'Organization admin dashboard requested without organization admin access.',
        );
      }

      return ref
          .read(dashboardRepositoryProvider)
          .loadOrganizationAdminSummary(session.profile);
    });
