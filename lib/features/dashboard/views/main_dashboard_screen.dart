import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/providers/auth_providers.dart';
import '../models/dashboard_destination.dart';
import '../../workspace/views/workspace_screen.dart';
import 'dashboard_scaffold.dart';
import 'organization_admin_dashboard_screen.dart';
import 'superadmin_dashboard_screen.dart';

class MainDashboardScreen extends ConsumerWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(currentAppSessionProvider);

    return sessionState.when(
      loading: () => const DashboardStatusView(
        icon: Icons.sync_rounded,
        title: 'Loading your dashboard',
        message:
            'Trellis is preparing the correct role-based landing experience.',
        loading: true,
      ),
      error: (error, _) => DashboardStatusView(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load your dashboard',
        message: '$error',
      ),
      data: (session) {
        if (session == null) {
          return const DashboardStatusView(
            icon: Icons.lock_outline_rounded,
            title: 'No active session',
            message: 'Sign in again to continue into the Trellis dashboard.',
          );
        }

        switch (resolveDashboardFor(session.profile.role)) {
          case DashboardDestination.teacherWorkspace:
            return const WorkspaceScreen();
          case DashboardDestination.organizationAdmin:
            return OrganizationAdminDashboardScreen(profile: session.profile);
          case DashboardDestination.superadmin:
            return SuperadminDashboardScreen(profile: session.profile);
        }
      },
    );
  }
}
