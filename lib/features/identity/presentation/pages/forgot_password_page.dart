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
import 'package:pickleball_platform/features/identity/domain/entities/password_reset_entities.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/forgot_password_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/validators/forgot_password_validators.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

/// Multi-step Forgot Password and recovery screen.
///
/// Steps:
/// 1. Enter registered mobile number (+91).
/// 2. Verify 6-digit OTP code with countdown timer and resend support.
/// 3. Set and confirm new password.
/// 4. Password reset confirmation and navigation back to Login.
class ForgotPasswordPage extends StatefulWidget {
  final ForgotPasswordCubit? cubit;
  final VoidCallback? onNavigateToLogin;
  final void Function(PasswordResetSuccessEntity)? onResetComplete;

  const ForgotPasswordPage({
    super.key,
    this.cubit,
    this.onNavigateToLogin,
    this.onResetComplete,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final ForgotPasswordCubit _cubit;
  late final bool _isInternalCubit;

  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AutovalidateMode _phoneAutovalidateMode = AutovalidateMode.disabled;
  AutovalidateMode _otpAutovalidateMode = AutovalidateMode.disabled;
  AutovalidateMode _passwordAutovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _isInternalCubit = false;
    } else if (sl.isRegistered<ForgotPasswordCubit>()) {
      _cubit = sl<ForgotPasswordCubit>();
      _isInternalCubit = true;
    } else {
      final repo = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>()
          : MockAuthRepository();
      _cubit = ForgotPasswordCubit(authRepository: repo);
      _isInternalCubit = true;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    if (_isInternalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _navigateToLogin() {
    if (widget.onNavigateToLogin != null) {
      widget.onNavigateToLogin!();
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _submitPhone() {
    FocusScope.of(context).unfocus();
    if (_phoneFormKey.currentState?.validate() ?? false) {
      _cubit.submitPhone(_phoneController.text.trim());
    } else {
      setState(() {
        _phoneAutovalidateMode = AutovalidateMode.onUserInteraction;
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

  void _submitNewPassword() {
    FocusScope.of(context).unfocus();
    if (_passwordFormKey.currentState?.validate() ?? false) {
      _cubit.submitNewPassword(
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    } else {
      setState(() {
        _passwordAutovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccessState) {
            widget.onResetComplete?.call(state.success);
          } else if (state is ForgotPasswordPhoneState) {
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

  Widget _buildCurrentStep(BuildContext context, ForgotPasswordState state) {
    return switch (state) {
      ForgotPasswordPhoneState() => _buildPhoneStep(context, state),
      ForgotPasswordOtpState() => _buildOtpStep(context, state),
      ForgotPasswordNewPasswordState() => _buildNewPasswordStep(context, state),
      ForgotPasswordSuccessState() => _buildSuccessStep(context, state),
    };
  }

  // --- Step 1: Mobile Number Input ---
  Widget _buildPhoneStep(BuildContext context, ForgotPasswordPhoneState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _phoneFormKey,
      autovalidateMode: _phoneAutovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: BrandLogoEmblem(size: 64)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Forgot Password',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Enter your registered mobile number and we'll send a 6-digit verification code to reset your password.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.errorMessage != null) ...[
            _buildErrorBanner(context, state.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            label: 'Mobile Number',
            hint: '98765 43210',
            controller: _phoneController,
            prefixText: '+91 ',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: ForgotPasswordValidators.validatePhone,
            onEditingComplete: _submitPhone,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(
            label: 'Send Verification Code',
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : _submitPhone,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: state.isSubmitting ? null : _navigateToLogin,
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

  // --- Step 2: OTP Verification ---
  Widget _buildOtpStep(BuildContext context, ForgotPasswordOtpState state) {
    final theme = Theme.of(context);

    return Form(
      key: _otpFormKey,
      autovalidateMode: _otpAutovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: BrandLogoEmblem(size: 56)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Verify Mobile Number',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the 6-digit code sent to',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.request.fullPhoneNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton.text(
                label: 'Change',
                onPressed: state.isVerifying || state.isResending
                    ? null
                    : _cubit.backToPhone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.errorMessage != null) ...[
            _buildErrorBanner(context, state.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            label: '6-Digit Verification Code',
            hint: '123456',
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: ForgotPasswordValidators.validateOtp,
            onEditingComplete: _submitOtp,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'Verify Code',
            isLoading: state.isVerifying,
            onPressed: state.isVerifying ? null : _submitOtp,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: state.countdown > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Resend code in ${state.countdown}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : AppButton.outline(
                    label: 'Resend Verification Code',
                    isLoading: state.isResending,
                    onPressed: state.canResend ? _cubit.resendOtp : null,
                  ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Set New Password ---
  Widget _buildNewPasswordStep(
    BuildContext context,
    ForgotPasswordNewPasswordState state,
  ) {
    final theme = Theme.of(context);

    return Form(
      key: _passwordFormKey,
      autovalidateMode: _passwordAutovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: BrandLogoEmblem(size: 56)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Set New Password',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a strong new password for your account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.errorMessage != null) ...[
            _buildErrorBanner(context, state.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField.password(
            label: 'New Password',
            hint: 'Enter new password',
            controller: _passwordController,
            textInputAction: TextInputAction.next,
            validator: ForgotPasswordValidators.validatePassword,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField.password(
            label: 'Confirm New Password',
            hint: 'Re-enter new password',
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            validator: (value) => ForgotPasswordValidators.validateConfirmPassword(
              _passwordController.text,
              value,
            ),
            onEditingComplete: _submitNewPassword,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(
            label: 'Reset Password',
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : _submitNewPassword,
          ),
        ],
      ),
    );
  }

  // --- Step 4: Password Reset Success ---
  Widget _buildSuccessStep(
    BuildContext context,
    ForgotPasswordSuccessState state,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Password Reset Successful',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your password has been updated successfully. You can now use your new password to sign in.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(80),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Account Mobile',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                state.success.phone,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppChip.success(label: 'Password Updated'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(
          label: 'Sign In with New Password',
          onPressed: _navigateToLogin,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
