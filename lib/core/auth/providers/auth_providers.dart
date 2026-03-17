import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_auth_session.dart';
import '../models/app_user_profile.dart';
import '../models/eligible_organization.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final userProfileProvider = FutureProvider.family<AppUserProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(authServiceProvider).loadUserProfile(uid);
});

final eligibleOrganizationsProvider =
    FutureProvider<List<EligibleOrganization>>((ref) {
      return ref.watch(authServiceProvider).loadEligibleOrganizations();
    });

final currentAppSessionProvider = FutureProvider<AppAuthSession?>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) {
    return null;
  }

  final profile = await ref.watch(userProfileProvider(user.uid).future);
  if (profile == null) {
    return null;
  }

  return AppAuthSession(user: user, profile: profile);
});
