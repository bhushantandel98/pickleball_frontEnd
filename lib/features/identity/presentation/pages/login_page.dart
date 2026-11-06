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
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/entities/auth_session.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/login_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/validators/login_validators.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

/// The Phone & Password Login screen.
///
/// Features mobile number validation (+91 Indian format), password obscurity toggle,
/// inline validation, loading states, error presentation, and responsive layouts.
class LoginPage extends StatefulWidget {
  final LoginCubit? cubit;
  final void Function(AuthSession session)? onLoginSuccess;
  final VoidCallback? onForgotPasswordPressed;
  final VoidCallback? onCreateAccountPressed;

  const LoginPage({
    super.key,
    this.cubit,
    this.onLoginSuccess,
    this.onForgotPasswordPressed,
    this.onCreateAccountPressed,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginCubit _cubit;
  late final bool _isInternalCubit;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _isInternalCubit = false;
    } else if (sl.isRegistered<LoginCubit>()) {
      _cubit = sl<LoginCubit>();
      _isInternalCubit = true;
    } else {
      final repo = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>()
          : MockAuthRepository();
      _cubit = LoginCubit(authRepository: repo);
      _isInternalCubit = true;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    if (_isInternalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleSuccess(AuthSession session) {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(session);
    } else {
      context.go(AppRoutes.loginSuccess);
    }
  }

  void _handleForgotPassword() {
    if (widget.onForgotPasswordPressed != null) {
      widget.onForgotPasswordPressed!();
    } else {
      context.push(AppRoutes.forgotPassword);
    }
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccountPressed != null) {
      widget.onCreateAccountPressed!();
    } else {
      context.push(AppRoutes.register);
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      _cubit.submitLogin(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            _handleSuccess(state.session);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

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
                            child: _buildForm(context, state, isLoading),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                              horizontal: AppSpacing.xs,
                            ),
                            child: _buildForm(context, state, isLoading),
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

  Widget _buildForm(BuildContext context, LoginState state, bool isLoading) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 1. Branding & Logo ---
          const Center(child: BrandLogoEmblem(size: 64.0)),
          const SizedBox(height: AppSpacing.lg),

          // --- 2. Heading & Subtitle ---
          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in to your account with your registered mobile number and password.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- 3. Error Banner (when LoginFailure) ---
          if (state is LoginFailure) ...[
            Container(
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
                children: [
                  Icon(
                    Icons.error_outline,
                    color: isDark ? AppColors.errorDark : AppColors.error,
                    size: AppSpacing.iconMd,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      state.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.errorDark : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // --- 4. Mobile Number Field ---
          AppTextField(
            controller: _phoneController,
            label: 'Mobile Number',
            hint: '98765 43210',
            enabled: !isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '+91 ',
            validator: LoginValidators.validatePhone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // --- 5. Password Field ---
          AppTextField.password(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            validator: LoginValidators.validatePassword,
            onEditingComplete: isLoading ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xs),

          // --- 6. Forgot Password Action ---
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- 7. Primary Sign In Button ---
          AppButton.primary(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- 8. Create Account Footer ---
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: isLoading ? null : _handleCreateAccount,
                child: Text(
                  'Create Account',
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
}
