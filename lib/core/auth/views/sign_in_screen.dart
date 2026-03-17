import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/functional_minimalism_widgets.dart';
import '../models/eligible_organization.dart';
import '../providers/auth_providers.dart';

enum _AuthMode { signIn, signUp }

enum _SignUpStep { account, organization }

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;
  String? _selectedOrganizationId;
  _AuthMode _mode = _AuthMode.signIn;
  _SignUpStep _signUpStep = _SignUpStep.account;

  bool get _isSignUp => _mode == _AuthMode.signUp;
  bool get _isOrganizationStep =>
      _isSignUp && _signUpStep == _SignUpStep.organization;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (_isSignUp && _signUpStep == _SignUpStep.account) {
      FocusScope.of(context).unfocus();
      setState(() {
        _errorMessage = null;
        _successMessage = null;
        _signUpStep = _SignUpStep.organization;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isSignUp) {
        await _submitSignUp();
      } else {
        await _submitSignIn();
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _submitSignIn() async {
    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _mapSignInError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Something went wrong while signing in. Please try again.';
      });
    }
  }

  Future<void> _submitSignUp() async {
    final organizationId = _selectedOrganizationId?.trim();
    if (organizationId == null || organizationId.isEmpty) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Choose an eligible organization.');
      return;
    }

    try {
      await ref
          .read(authServiceProvider)
          .signUpTeacherRequest(
            displayName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            organizationId: organizationId,
          );

      final organizations = await ref.read(
        eligibleOrganizationsProvider.future,
      );
      final organizationName = _resolveOrganizationName(
        organizations,
        organizationId,
      );

      await ref.read(authServiceProvider).signOut();

      if (!mounted) return;
      setState(() {
        _mode = _AuthMode.signIn;
        _signUpStep = _SignUpStep.account;
        _selectedOrganizationId = null;
        _passwordController.clear();
        _confirmPasswordController.clear();
        _errorMessage = null;
        _successMessage =
            'Access request sent to $organizationName. Your account stays inactive until an administrator approves it.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _mapSignUpError(error));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _mapSignUpDataError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Something went wrong while creating your access request. Please try again.';
      });
    }
  }

  void _setMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _signUpStep = _SignUpStep.account;
      _selectedOrganizationId = null;
      _errorMessage = null;
      _successMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String _mapSignInError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email and password do not match.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unable to sign in right now.';
    }
  }

  String _mapSignUpError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Sign in instead or use another email.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Sign-up is not available right now.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unable to create your access request right now.';
    }
  }

  String _mapSignUpDataError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'This organization is not eligible for sign-up right now.';
      case 'unavailable':
        return 'Sign-up is temporarily unavailable. Please try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unable to save your access request right now.';
    }
  }

  String _resolveOrganizationName(
    List<EligibleOrganization> organizations,
    String organizationId,
  ) {
    for (final organization in organizations) {
      if (organization.id == organizationId) return organization.name;
    }
    return organizationId;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 980;
    final organizationsState = ref.watch(eligibleOrganizationsProvider);
    final blockSubmit =
        _isOrganizationStep &&
        (!organizationsState.hasValue ||
            organizationsState.requireValue.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFF), Color(0xFFF1F6FF), AppColors.canvas],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft.withValues(alpha: 0.72),
                ),
              ),
            ),
            Positioned(
              left: -120,
              bottom: -180,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondarySoft.withValues(alpha: 0.7),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _AuthBackdropPainter()),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingLg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1360),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: compact ? 0 : 760),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.9),
                          width: 1.4,
                        ),
                        boxShadow: AppShadows.surface,
                      ),
                      child: compact
                          ? Column(
                              children: [
                                TrellisStaggeredReveal(
                                  index: 0,
                                  child: _VisualPanel(
                                    compact: true,
                                    signUp: _isSignUp,
                                    organizationStep: _isOrganizationStep,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.paddingLg),
                                TrellisStaggeredReveal(
                                  index: 1,
                                  child: _buildForm(
                                    context,
                                    organizationsState,
                                    blockSubmit,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: TrellisStaggeredReveal(
                                    index: 0,
                                    child: _buildForm(
                                      context,
                                      organizationsState,
                                      blockSubmit,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.paddingLg),
                                Expanded(
                                  flex: 10,
                                  child: TrellisStaggeredReveal(
                                    index: 1,
                                    child: _VisualPanel(
                                      compact: false,
                                      signUp: _isSignUp,
                                      organizationStep: _isOrganizationStep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AsyncValue<List<EligibleOrganization>> organizationsState,
    bool blockSubmit,
  ) {
    final title = !_isSignUp
        ? 'Welcome back'
        : _isOrganizationStep
        ? 'Choose your\norganization'
        : 'Create your\naccount';
    final subtitle = !_isSignUp
        ? 'Sign in with the account your organization already manages and return to the work that matters today.'
        : _isOrganizationStep
        ? 'Pick the organization that should review this request. New accounts stay inactive until approval.'
        : 'Start with your account details first, then choose the organization that should review access.';
    final modeLabel = !_isSignUp
        ? 'Private staff access'
        : _isOrganizationStep
        ? 'Teacher access request'
        : 'Account request setup';
    final supportNote = !_isSignUp
        ? 'Organization-managed identity'
        : _isOrganizationStep
        ? 'Approval stays with the organization'
        : 'Your request remains pending until approval';

    return Padding(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 980
            ? AppSizes.paddingLg
            : AppSizes.paddingXl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surfaceRaised, AppColors.primarySoft],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset(
                    'assets/trellis-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trellis', style: AppTextStyles.subheading),
                      const SizedBox(height: 4),
                      Text(modeLabel, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                TrellisInfoBadge(
                  label: supportNote,
                  accent: _isSignUp
                      ? TrellisAccentPalette.warning(
                          icon: Icons.how_to_reg_rounded,
                        )
                      : TrellisAccentPalette.primary(icon: Icons.login_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLg),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Sign in',
                      selected: !_isSignUp,
                      onTap: () => _setMode(_AuthMode.signIn),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ModeButton(
                      label: 'Sign up',
                      selected: _isSignUp,
                      onTap: () => _setMode(_AuthMode.signUp),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingXl),
            TrellisSmoothSwitcher(
              switchKey: '$_mode-$_signUpStep',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.display.copyWith(
                      fontSize: _isOrganizationStep ? 42 : 52,
                      height: 0.96,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            Wrap(
              spacing: AppSizes.paddingSm,
              runSpacing: AppSizes.paddingSm,
              children: [
                TrellisInfoBadge(
                  label: !_isSignUp ? 'Secure sign-in' : 'Approval required',
                  accent: TrellisAccentPalette.primary(
                    icon: Icons.verified_user_rounded,
                  ),
                ),
                TrellisInfoBadge(
                  label: 'Smooth role routing',
                  accent: TrellisAccentPalette.byIndex(
                    5,
                    icon: Icons.alt_route_rounded,
                  ),
                ),
              ],
            ),
            if (_isSignUp) ...[
              const SizedBox(height: AppSizes.paddingLg),
              Row(
                children: [
                  Expanded(
                    child: _StepBadge(
                      label: '01 Account',
                      active: true,
                      done: _isOrganizationStep,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMd),
                  Expanded(
                    child: _StepBadge(
                      label: '02 Organization',
                      active: _isOrganizationStep,
                      done: false,
                    ),
                  ),
                ],
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: AppSizes.paddingLg),
              _MessageStrip(
                message: _successMessage!,
                background: AppColors.primarySoft,
                foreground: AppColors.primary,
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.paddingLg),
              _MessageStrip(
                message: _errorMessage!,
                background: const Color(0xFFF7E2DB),
                foreground: AppColors.danger,
                icon: Icons.error_outline_rounded,
              ),
            ],
            const SizedBox(height: AppSizes.paddingXl),
            if (!_isOrganizationStep) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !_isSignUp
                          ? 'Account credentials'
                          : 'Tell us about your account',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXs),
                    Text(
                      !_isSignUp
                          ? 'Use the e-mail and password already assigned by your organization.'
                          : 'These details create the pending account request your organization will review.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSizes.paddingLg),
                    if (_isSignUp) ...[
                      _label('Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _decoration(
                          'Enter your name',
                          prefixIcon: Icons.badge_rounded,
                        ),
                        validator: (value) {
                          if (!_isSignUp) return null;
                          if ((value?.trim() ?? '').isEmpty) {
                            return 'Full name is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.paddingLg),
                    ],
                    _label('E-mail'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration(
                        'Enter your email address',
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Email is required.';
                        }
                        if (!email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingLg),
                    _label('Password'),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _decoration(
                        _isSignUp
                            ? 'Create your password'
                            : 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.isEmpty) return 'Password is required.';
                        if (_isSignUp && password.length < 6) {
                          return 'Use at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: AppSizes.paddingLg),
                      _label('Confirm password'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _decoration(
                          'Repeat your password',
                          prefixIcon: Icons.lock_clock_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (!_isSignUp) return null;
                          if ((value ?? '').isEmpty) {
                            return 'Confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account details',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Text(
                      'Name: ${_nameController.text.trim()}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'E-mail: ${_emailController.text.trim()}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),
              _label('Eligible organization'),
              const SizedBox(height: AppSizes.paddingSm),
              _buildOrganizationChooser(organizationsState),
            ],
            const SizedBox(height: AppSizes.paddingXl),
            Row(
              children: [
                if (_isOrganizationStep) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() {
                              _signUpStep = _SignUpStep.account;
                              _errorMessage = null;
                              _successMessage = null;
                            }),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMd),
                ],
                Expanded(
                  flex: _isOrganizationStep ? 2 : 1,
                  child: FilledButton(
                    onPressed: _submitting || blockSubmit ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(
                            !_isSignUp
                                ? 'Continue'
                                : _isOrganizationStep
                                ? 'Request access'
                                : 'Next step',
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              !_isSignUp
                  ? 'Need access? Create an account request, then wait for organization approval.'
                  : _isOrganizationStep
                  ? 'Only active organizations appear here, and your request stays pending until approval.'
                  : 'After this step, you will choose the organization that should review your request.',
              style: AppTextStyles.caption.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _decoration(
    String hint, {
    Widget? suffix,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      filled: true,
      fillColor: AppColors.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: 20,
      ),
    );
  }

  Widget _buildOrganizationChooser(
    AsyncValue<List<EligibleOrganization>> organizationsState,
  ) {
    return organizationsState.when(
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              'Loading eligible organizations...',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
      error: (error, _) => _MessageStrip(
        message: 'Unable to load eligible organizations: $error',
        background: const Color(0xFFF7E2DB),
        foreground: AppColors.danger,
        icon: Icons.error_outline_rounded,
      ),
      data: (organizations) {
        if (organizations.isEmpty) {
          return _MessageStrip(
            message:
                'No active organizations are accepting self-sign-up right now.',
            background: AppColors.secondarySoft,
            foreground: AppColors.textPrimary,
            icon: Icons.domain_disabled_rounded,
          );
        }

        return Column(
          children: [
            for (var index = 0; index < organizations.length; index++) ...[
              _OrganizationCard(
                organization: organizations[index],
                selected: _selectedOrganizationId == organizations[index].id,
                index: index,
                onTap: () => setState(() {
                  _selectedOrganizationId = organizations[index].id;
                }),
              ),
              if (index != organizations.length - 1)
                const SizedBox(height: AppSizes.paddingMd),
            ],
          ],
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active || done ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: active || done ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active || done
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageStrip extends StatelessWidget {
  const _MessageStrip({
    required this.message,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String message;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: foreground.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.organization,
    required this.selected,
    required this.index,
    required this.onTap,
  });

  final EligibleOrganization organization;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? TrellisAccentPalette.primary(icon: Icons.domain_verification_rounded)
        : TrellisAccentPalette.byIndex(
            index + 1,
            icon: Icons.apartment_rounded,
          );

    return TrellisPressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            TrellisAccentIcon(
              accent: accent,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(14),
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
                  Text(organization.id, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualPanel extends StatelessWidget {
  const _VisualPanel({
    required this.compact,
    required this.signUp,
    required this.organizationStep,
  });

  final bool compact;
  final bool signUp;
  final bool organizationStep;

  @override
  Widget build(BuildContext context) {
    final title = signUp
        ? organizationStep
              ? 'Match with the right organization.'
              : 'Start your Trellis access request.'
        : 'Return to a calm, role-shaped workspace.';
    final subtitle = signUp
        ? 'Organizations stay explicit, approvals stay controlled, and access only opens when the right team says yes.'
        : 'Teachers, organization admins, and superadmins all land where their work actually starts.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 320 : 760),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF2FF), Color(0xFFF8FBFF), Color(0xFFDDEBFF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _VisualPainter())),
            Positioned(
              top: 24,
              left: 24,
              child: TrellisInfoBadge(
                label: signUp ? 'Controlled sign-up' : 'Private sign-in',
                accent: signUp
                    ? TrellisAccentPalette.warning(
                        icon: Icons.auto_awesome_rounded,
                      )
                    : TrellisAccentPalette.primary(
                        icon: Icons.workspace_premium_rounded,
                      ),
              ),
            ),
            Positioned(
              top: compact ? 86 : 42,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signUp ? 'Eligible orgs' : 'Role entry',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      signUp ? 'Active only' : 'Role first',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: compact
                  ? Alignment.bottomCenter
                  : Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(compact ? 24 : 34),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.display.copyWith(
                                fontSize: compact ? 34 : 44,
                                height: 0.98,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingMd),
                            Text(
                              subtitle,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLg),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingLg),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          signUp
                              ? 'Self-registration stays narrow: account first, organization next, approval before access.'
                              : 'One sign-in, then Trellis routes each person into a dashboard shaped for their responsibilities.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(-40, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.02,
        size.width * 0.34,
        -12,
      );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VisualPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final widePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.4);
    final thinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary.withValues(alpha: 0.18);

    final one = Path()
      ..moveTo(size.width * 0.02, size.height * 0.32)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.06,
        size.width * 0.56,
        size.height * 0.16,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 1.02,
        size.height * 0.08,
      );
    final two = Path()
      ..moveTo(size.width * 0.08, size.height * 0.84)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.54,
        size.width * 0.72,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.72,
        size.width * 1.04,
        size.height * 0.54,
      );
    canvas.drawPath(one, widePaint);
    canvas.drawPath(two, thinPaint);

    final orbPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.26),
              AppColors.secondary.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.64, size.height * 0.48),
              radius: size.width * 0.24,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.48),
      size.width * 0.24,
      orbPaint,
    );

    final cardPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.1);
    canvas.save();
    canvas.translate(size.width * 0.18, size.height * 0.18);
    canvas.rotate(-math.pi / 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * 0.24, size.height * 0.14),
        const Radius.circular(28),
      ),
      cardPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
