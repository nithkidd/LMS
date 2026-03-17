import 'package:firebase_auth/firebase_auth.dart';

import 'app_user_profile.dart';

class AppAuthSession {
  const AppAuthSession({required this.user, required this.profile});

  final User user;
  final AppUserProfile profile;
}
