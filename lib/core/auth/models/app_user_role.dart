enum AppUserRole {
  superadmin,
  organizationAdmin,
  teacher;

  static AppUserRole? fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
        return AppUserRole.superadmin;
      case 'organizationadmin':
      case 'organization_admin':
      case 'orgadmin':
      case 'org_admin':
      case 'admin':
        return AppUserRole.organizationAdmin;
      case 'teacher':
        return AppUserRole.teacher;
      default:
        return null;
    }
  }

  String get storageValue {
    switch (this) {
      case AppUserRole.superadmin:
        return 'superadmin';
      case AppUserRole.organizationAdmin:
        return 'org_admin';
      case AppUserRole.teacher:
        return 'teacher';
    }
  }

  String get label {
    switch (this) {
      case AppUserRole.superadmin:
        return 'Superadmin';
      case AppUserRole.organizationAdmin:
        return 'Organization Admin';
      case AppUserRole.teacher:
        return 'Teacher';
    }
  }
}
