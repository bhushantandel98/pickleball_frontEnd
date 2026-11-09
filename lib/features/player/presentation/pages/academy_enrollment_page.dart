import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_enrollment_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_enrollment_state.dart';

/// Form page for submitting an academy enrollment request or joining a batch waitlist.
class AcademyEnrollmentPage extends StatefulWidget {
  final String branchId;
  final String programId;
  final String batchId;
  final AcademyEnrollmentCubit? cubit;

  const AcademyEnrollmentPage({
    super.key,
    required this.branchId,
    required this.programId,
    required this.batchId,
    this.cubit,
  });

  @override
  State<AcademyEnrollmentPage> createState() => _AcademyEnrollmentPageState();
}

class _AcademyEnrollmentPageState extends State<AcademyEnrollmentPage> {
  late final AcademyEnrollmentCubit _cubit;

  final TextEditingController _nameController =
      TextEditingController(text: 'Alex Rivera');
  final TextEditingController _phoneController =
      TextEditingController(text: '+91 98765 43210');
  final TextEditingController _emailController =
      TextEditingController(text: 'alex.rivera@example.com');
  final TextEditingController _ratingController =
      TextEditingController(text: '3.8');
  final TextEditingController _emergencyNameController =
      TextEditingController(text: 'Carlos Rivera');
  final TextEditingController _emergencyPhoneController =
      TextEditingController(text: '+91 98765 43211');
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ??
        AcademyEnrollmentCubit(sl<CoachingAcademyRepository>());
    _cubit.init(
      branchId: widget.branchId,
      programId: widget.programId,
      batchId: widget.batchId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ratingController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    if (widget.cubit == null) _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Request Academy Enrollment'),
        body: BlocConsumer<AcademyEnrollmentCubit, AcademyEnrollmentState>(
          listener: (context, state) {
            if (state is AcademyEnrollmentReady && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AcademyEnrollmentInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AcademyEnrollmentFailure) {
              return Center(
                child: ErrorStateView(
                  message: state.message,
                  onRetry: () => _cubit.init(
                    branchId: widget.branchId,
                    programId: widget.programId,
                    batchId: widget.batchId,
                  ),
                ),
              );
            }

            if (state is AcademyEnrollmentSuccess) {
              final req = state.request;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          req.isWaitlist
                              ? Icons.hourglass_top_outlined
                              : Icons.check_circle_outline,
                          size: 64,
                          color: req.isWaitlist
                              ? Colors.amber.shade700
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          req.isWaitlist
                              ? 'Added to Batch Waitlist!'
                              : 'Enrollment Request Submitted!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          req.isWaitlist
                              ? 'You are at position #${req.waitlistPosition ?? 1} on the waitlist. You will be notified when a slot opens.'
                              : 'Your application has been received and is pending academy approval.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reference ID:'),
                            Text(
                              req.id,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Program:'),
                            Flexible(
                              child: Text(
                                req.programTitle,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Batch:'),
                            Flexible(
                              child: Text(
                                req.batchName,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Initial Status:'),
                            req.isWaitlist
                                ? const AppChip.warning(label: 'On Waitlist')
                                : const AppChip.info(label: 'Pending Approval'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton.primary(
                            label: 'Back to Academies & Coaches',
                            onPressed: () {
                              context.go(AppRoutes.playerAcademies);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (state is AcademyEnrollmentReady) {
              final branch = state.branch;
              final program = state.program;
              final batch = state.batch;
              final isWaitlist = batch.isFull && batch.isWaitlistEnabled;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Banner
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  branch.academyName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isWaitlist)
                                const AppChip.warning(label: 'Waitlist Application')
                              else
                                const AppChip.success(label: 'Spots Available'),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Branch: ${branch.branchName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Divider(height: 16),
                          Text(
                            program.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Batch: ${batch.name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Schedule: ${batch.schedule}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isWaitlist) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.amber.shade900,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This batch is currently full. Submitting this form will register you at waitlist position #${batch.waitlistCount + 1}.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Important Approval Notice
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Academy Enrollment Policy:\nEnrollment requires explicit academy approval. Applications are reviewed by staff and are not auto-approved.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Inputs Section
                    Text(
                      'Applicant Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      hint: 'Enter your name',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _phoneController,
                      label: 'Mobile Number *',
                      hint: '+91 98765 43210',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address (Optional)',
                      hint: 'player@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _ratingController,
                      label: 'DUPR / Skill Rating (Optional)',
                      hint: 'e.g. 3.5',
                      prefixIcon: const Icon(Icons.sports_score_outlined),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Emergency Contact',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppTextField(
                      controller: _emergencyNameController,
                      label: 'Emergency Contact Name *',
                      hint: 'Relative or Guardian',
                      prefixIcon: const Icon(Icons.contact_phone_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _emergencyPhoneController,
                      label: 'Emergency Contact Phone *',
                      hint: '+91 98765 43211',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _notesController,
                      label: 'Special Notes / Goals (Optional)',
                      hint: 'e.g. Tournament prep, medical considerations, training history...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submission CTA
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: state.isSubmitting
                            ? 'Submitting Request...'
                            : (isWaitlist
                                ? 'Join Batch Waitlist'
                                : 'Submit Enrollment Request'),
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                final rating = double.tryParse(_ratingController.text);
                                _cubit.submitEnrollment(
                                  playerName: _nameController.text,
                                  playerPhone: _phoneController.text,
                                  playerEmail: _emailController.text,
                                  playerRating: rating,
                                  emergencyContactName:
                                      _emergencyNameController.text,
                                  emergencyContactPhone:
                                      _emergencyPhoneController.text,
                                  notes: _notesController.text,
                                );
                              },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
