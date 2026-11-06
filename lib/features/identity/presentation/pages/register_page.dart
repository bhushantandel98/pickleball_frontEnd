import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/entities/registration_entities.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/registration_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/validators/registration_validators.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

/// Multi-step Player self-registration and mobile OTP verification screen.
///
/// Follows Platform Rules:
/// - A newly registered user strictly receives an independent Player account.
/// - Coach, Academy, Venue, and other organization roles are never automatically granted.
/// - Includes required mobile verification, inline validation, and visible resend countdown.
class RegisterPage extends StatefulWidget {
  final RegistrationCubit? cubit;
  final VoidCallback? onNavigateToLogin;
  final void Function(PlayerRegistrationSuccessEntity)? onRegistrationComplete;

  const RegisterPage({
    super.key,
    this.cubit,
    this.onNavigateToLogin,
    this.onRegistrationComplete,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final RegistrationCubit _cubit;
  late final bool _isInternalCubit;

  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  AutovalidateMode _formAutovalidateMode = AutovalidateMode.disabled;
  AutovalidateMode _otpAutovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _isInternalCubit = false;
    } else if (sl.isRegistered<RegistrationCubit>()) {
      _cubit = sl<RegistrationCubit>();
      _isInternalCubit = true;
    } else {
      final repo = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>()
          : MockAuthRepository();
      _cubit = RegistrationCubit(authRepository: repo);
      _isInternalCubit = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    if (_isInternalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleNavigateToLogin() {
    if (widget.onNavigateToLogin != null) {
      widget.onNavigateToLogin!();
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      _cubit.submitRegistrationForm(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      setState(() {
        _formAutovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  void _submitOtp() {
    FocusScope.of(context).unfocus();
    if (_otpFormKey.currentState?.validate() ?? false) {
      _cubit.submitOtp(_otpController.text.trim());
    } else {
      setState(() {
        _otpAutovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RegistrationCubit, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationCompletedState) {
            widget.onRegistrationComplete?.call(state.success);
          } else if (state is RegistrationFormState) {
            if (state.initialFullName != null && _nameController.text.isEmpty) {
              _nameController.text = state.initialFullName!;
            }
            if (state.initialPhone != null && _phoneController.text.isEmpty) {
              _phoneController.text = state.initialPhone!;
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.screenPadding,
                  child: ResponsiveContainer(
                    maxWidth: AppSpacing.maxFormWidth,
                    child: isDesktop
                        ? AppCard(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: _buildCurrentStep(context, state),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                              horizontal: AppSpacing.xs,
                            ),
                            child: _buildCurrentStep(context, state),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, RegistrationState state) {
    switch (state) {
      case RegistrationFormState():
        return _buildFormStep(context, state);
      case RegistrationOtpState():
        return _buildOtpStep(context, state);
      case RegistrationCompletedState():
        return _buildSuccessStep(context, state);
    }
  }

  // ===========================================================================
  // Step 1: Registration Form
  // ===========================================================================
  Widget _buildFormStep(BuildContext context, RegistrationFormState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      autovalidateMode: _formAutovalidateMode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandLogoEmblem(size: 64.0)),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Create Player Account',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign up as an independent player to book courts, join tournaments, and connect with coaches.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Error banner
          if (state.errorMessage != null) ...[
            _buildErrorBanner(context, state.errorMessage!, isDark),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Full Name
          AppTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            enabled: !state.isSubmitting,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.person_outline),
            validator: RegistrationValidators.validateFullName,
          ),
          const SizedBox(height: AppSpacing.md),

          // Mobile Number
          AppTextField(
            controller: _phoneController,
            label: 'Mobile Number',
            hint: '98765 43210',
            enabled: !state.isSubmitting,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '+91 ',
            validator: RegistrationValidators.validatePhone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Password
          AppTextField.password(
            controller: _passwordController,
            label: 'Password',
            hint: 'At least 8 characters with letters & numbers',
            enabled: !state.isSubmitting,
            textInputAction: TextInputAction.next,
            validator: RegistrationValidators.validatePassword,
          ),
          const SizedBox(height: AppSpacing.md),

          // Confirm Password
          AppTextField.password(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            enabled: !state.isSubmitting,
            textInputAction: TextInputAction.done,
            validator: (val) => RegistrationValidators.validateConfirmPassword(
              val,
              _passwordController.text,
            ),
            onEditingComplete: state.isSubmitting ? null : _submitForm,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit Action
          AppButton.primary(
            label: 'Send Verification Code',
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : _submitForm,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Sign In Footer
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: state.isSubmitting ? null : _handleNavigateToLogin,
                child: Text(
                  'Sign In',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 2: OTP Verification Screen
  // ===========================================================================
  Widget _buildOtpStep(BuildContext context, RegistrationOtpState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _otpFormKey,
      autovalidateMode: _otpAutovalidateMode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 56.0,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Verify Mobile Number',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the 6-digit verification code sent to ${state.request.fullPhoneNumber}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: state.isVerifying || state.isResending
                  ? null
                  : () => _cubit.backToForm(),
              child: Text(
                'Change mobile number',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Error banner
          if (state.errorMessage != null) ...[
            _buildErrorBanner(context, state.errorMessage!, isDark),
            const SizedBox(height: AppSpacing.lg),
          ],

          // OTP Input
          AppTextField(
            controller: _otpController,
            label: 'Verification Code (OTP)',
            hint: '123456',
            enabled: !state.isVerifying,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.pin_outlined),
            validator: RegistrationValidators.validateOtp,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onEditingComplete: state.isVerifying ? null : _submitOtp,
          ),
          const SizedBox(height: AppSpacing.md),

          // Resend Code Countdown & Trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.countdown > 0)
                Text(
                  'Resend code in 00:${state.countdown.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                )
              else
                TextButton(
                  onPressed: state.canResend ? () => _cubit.resendOtp() : null,
                  child: state.isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Resend Code',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Verify Button
          AppButton.primary(
            label: 'Verify & Complete Registration',
            isLoading: state.isVerifying,
            onPressed: state.isVerifying ? null : _submitOtp,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cancel / Back to Login
          Center(
            child: TextButton(
              onPressed: state.isVerifying ? null : _handleNavigateToLogin,
              child: Text(
                'Cancel and Return to Sign In',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 3: Registration Success Screen
  // ===========================================================================
  Widget _buildSuccessStep(
    BuildContext context,
    RegistrationCompletedState state,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.check_circle_outline,
            size: 72.0,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Account Created!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Welcome to Pickleball, ${state.success.fullName}!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your mobile number (${state.success.phone}) has been verified. You can now sign in with your credentials.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Role Scope Notice Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppChip.success(
                    label: 'Player Role',
                  ),
                  const Spacer(),
                  Icon(
                    Icons.verified_user_outlined,
                    size: AppSpacing.iconSm,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'An independent Player profile has been provisioned. Coach, Academy, Venue, and Tournament roles require separate organizational onboarding or invitations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Proceed to Sign In CTA
        AppButton.primary(
          label: 'Proceed to Sign In',
          onPressed: _handleNavigateToLogin,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.errorDark.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.errorDark : AppColors.error,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: isDark ? AppColors.errorDark : AppColors.error,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.errorDark : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
