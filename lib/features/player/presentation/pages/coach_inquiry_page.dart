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
import 'package:pickleball_platform/features/player/presentation/cubit/coach_inquiry_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_inquiry_state.dart';

/// Form page for submitting a coaching inquiry or connection request to a registered coach.
class CoachInquiryPage extends StatefulWidget {
  final String coachId;
  final String? serviceId;
  final CoachInquiryCubit? cubit;

  const CoachInquiryPage({
    super.key,
    required this.coachId,
    this.serviceId,
    this.cubit,
  });

  @override
  State<CoachInquiryPage> createState() => _CoachInquiryPageState();
}

class _CoachInquiryPageState extends State<CoachInquiryPage> {
  late final CoachInquiryCubit _cubit;

  final TextEditingController _nameController =
      TextEditingController(text: 'Alex Rivera');
  final TextEditingController _phoneController =
      TextEditingController(text: '+91 98765 43210');
  final TextEditingController _emailController =
      TextEditingController(text: 'alex.rivera@example.com');
  final TextEditingController _daysController =
      TextEditingController(text: 'Weekday mornings (Tue/Thu 7:00 AM)');
  final TextEditingController _ratingController =
      TextEditingController(text: '3.8');
  final TextEditingController _goalController =
      TextEditingController(text: 'Improve third-shot drop consistency and transition reset drops');
  final TextEditingController _messageController = TextEditingController(
    text: 'Looking to schedule private lessons to prepare for an upcoming tournament.',
  );

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ??
        CoachInquiryCubit(sl<CoachingAcademyRepository>());
    _cubit.init(
      coachId: widget.coachId,
      preSelectedServiceId: widget.serviceId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _daysController.dispose();
    _ratingController.dispose();
    _goalController.dispose();
    _messageController.dispose();
    if (widget.cubit == null) _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Coaching Inquiry'),
        body: BlocConsumer<CoachInquiryCubit, CoachInquiryState>(
          listener: (context, state) {
            if (state is CoachInquiryReady && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CoachInquiryInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CoachInquiryFailure) {
              return Center(
                child: ErrorStateView(
                  message: state.message,
                  onRetry: () => _cubit.init(
                    coachId: widget.coachId,
                    preSelectedServiceId: widget.serviceId,
                  ),
                ),
              );
            }

            if (state is CoachInquirySuccess) {
              final inq = state.inquiry;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Inquiry Sent to Coach!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Coach ${inq.coachName} will review your inquiry and reach out. Note that coaching access is granted only after the coach accepts.',
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
                              inq.id,
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
                            const Text('Coach:'),
                            Text(
                              inq.coachName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (inq.serviceName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Service:'),
                              Flexible(
                                child: Text(
                                  inq.serviceName!,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status:'),
                            const AppChip.warning(label: 'Awaiting Coach Review'),
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

            if (state is CoachInquiryReady) {
              final coach = state.coach;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coach Header Banner
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              coach.name
                                  .split(' ')
                                  .where((p) => p.isNotEmpty)
                                  .take(2)
                                  .map((p) => p[0])
                                  .join(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coach.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  coach.title,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppChip.info(label: coach.city),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Access policy banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_clock_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Platform Policy:\nSubmitting an inquiry initiates a connection with the coach. Dashboard coaching access is granted exclusively after the coach reviews and accepts.',
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

                    // Service Selection (if coach has multiple services)
                    if (coach.services.isNotEmpty) ...[
                      Text(
                        'Select Service / Offering',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...coach.services.map((srv) {
                        final isSelected = state.selectedServiceId == srv.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => _cubit.selectService(srv.id),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4)
                                    : theme.colorScheme.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          srv.name,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${srv.duration} • ${srv.feeDisplay}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Form Fields
                    Text(
                      'Your Details & Availability',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      hint: 'Alex Rivera',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number *',
                      hint: '+91 98765 43210',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _emailController,
                      label: 'Email (Optional)',
                      hint: 'player@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _daysController,
                      label: 'Preferred Days & Times *',
                      hint: 'e.g. Tue / Thu mornings, weekends',
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _ratingController,
                      label: 'Your Current DUPR / Skill Rating (Optional)',
                      hint: 'e.g. 3.5',
                      prefixIcon: const Icon(Icons.sports_score_outlined),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _goalController,
                      label: 'Primary Training Focus / Goal *',
                      hint: 'e.g. Third shot drops, resetting power hits, tournament prep...',
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _messageController,
                      label: 'Message for Coach *',
                      hint: 'Provide any additional context or questions...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit CTA
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: state.isSubmitting
                            ? 'Sending Inquiry...'
                            : 'Send Coaching Inquiry',
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                final rating = double.tryParse(_ratingController.text);
                                _cubit.submitInquiry(
                                  playerName: _nameController.text,
                                  playerPhone: _phoneController.text,
                                  playerEmail: _emailController.text,
                                  preferredDays: _daysController.text,
                                  playerRating: rating,
                                  trainingGoal: _goalController.text,
                                  message: _messageController.text,
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
