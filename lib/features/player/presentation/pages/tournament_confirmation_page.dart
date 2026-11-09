import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

/// Screen presenting the registration confirmation receipt, reference ID, and next match day actions.
class TournamentConfirmationPage extends StatelessWidget {
  final String tournamentId;
  final TournamentRegistration? registration;

  const TournamentConfirmationPage({
    super.key,
    required this.tournamentId,
    this.registration,
  });

  void _copyReference(BuildContext context, String reference) {
    Clipboard.setData(ClipboardData(text: reference));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration reference copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reg = registration ??
        TournamentRegistration(
          id: 'PKL-TRN-20261120-4821',
          tournamentId: tournamentId,
          tournamentName: 'Tournament Registration',
          categoryId: 'cat_default',
          categoryName: 'Pickleball Division',
          venueName: 'Tournament Arena',
          dates: 'November 2026',
          playerName: 'Alex Rivera',
          entryFee: 1200.0,
          status: TournamentRegistrationStatus.confirmed,
          registeredAt: DateTime.now(),
        );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CommonAppBar(
          title: 'Registration Confirmed',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.playerTournaments),
          ),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: AppSpacing.maxContentWidth,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // Success Icon & Title
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: reg.isWaitlisted
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reg.isWaitlisted
                      ? Icons.hourglass_top_outlined
                      : Icons.check_circle_outline,
                  size: 40,
                  color: reg.isWaitlisted
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                reg.isWaitlisted
                    ? 'Added to Category Waitlist!'
                    : 'Registration Confirmed!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                reg.isWaitlisted
                    ? 'You are on the official waitlist. We will notify you if an entry slot opens up.'
                    : 'You are officially entered into the tournament. See you on the courts!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reference Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Registration Reference',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        reg.isWaitlisted
                            ? const AppChip.warning(label: 'Waitlist')
                            : const AppChip.success(label: 'Confirmed'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reg.id,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          IconButton(
                            key: const Key('copy_registration_reference_button'),
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy Reference',
                            onPressed: () => _copyReference(context, reg.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Details Summary Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(context, 'Tournament', reg.tournamentName),
                    _buildDetailRow(context, 'Division', reg.categoryName),
                    _buildDetailRow(context, 'Venue', reg.venueName),
                    _buildDetailRow(context, 'Dates', reg.dates),
                    _buildDetailRow(context, 'Player', reg.playerName),
                    if (reg.partnerName != null && reg.partnerName!.isNotEmpty)
                      _buildDetailRow(context, 'Partner', reg.partnerName!),
                    _buildDetailRow(context, 'Total Fee', reg.formattedFee),
                    _buildDetailRow(context, 'Payment Status', reg.paymentStatus),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Instructions Notice Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Match Day Instructions',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Report to the Tournament Desk at least 20 minutes before match time.\n'
                            '• Entry fee will be collected at the venue desk.\n'
                            '• Track live match schedules in the Match Day Hub.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              AppButton.primary(
                key: const Key('confirmation_match_day_button'),
                label: 'Go to Match Day Hub',
                icon: const Icon(Icons.scoreboard_outlined),
                width: double.infinity,
                onPressed: () => context.go(AppRoutes.playerMatchDay),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                key: const Key('confirmation_tournaments_button'),
                label: 'Back to Tournaments',
                icon: const Icon(Icons.emoji_events_outlined),
                width: double.infinity,
                onPressed: () => context.go(AppRoutes.playerTournaments),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('confirmation_dashboard_button'),
                onPressed: () => context.go(AppRoutes.playerDashboard),
                child: const Text('Back to Player Dashboard'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
