import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Displays permitted coach finance summaries while strictly separating
/// Personal Coaching finance from each Accepted Academy's finance.
class CoachFinanceSummarySection extends StatelessWidget {
  final bool showPersonalContext;
  final bool showAcademyContext;
  final PersonalFinanceSummary? personalFinance;
  final List<AcademyFinanceSummary> academyFinances;

  const CoachFinanceSummarySection({
    super.key,
    required this.showPersonalContext,
    required this.showAcademyContext,
    required this.personalFinance,
    required this.academyFinances,
  });

  String _formatAmount(String symbol, double amount) {
    final whole = amount.round();
    final str = whole.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return '$symbol${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPersonal = showPersonalContext && personalFinance != null;
    final hasAcademy = showAcademyContext && academyFinances.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Finance Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            'Permitted coach payout summaries only • Personal and academy finances are kept separate',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasPersonal && !hasAcademy)
          AppCard(
            key: const Key('coach_finance_empty'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'No permitted finance summaries available for the selected context.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          if (hasPersonal) ...[
            _PersonalFinanceCard(
              summary: personalFinance!,
              formatAmount: _formatAmount,
            ),
            if (hasAcademy) const SizedBox(height: AppSpacing.sm),
          ],
          if (hasAcademy)
            Column(
              children: [
                for (int i = 0; i < academyFinances.length; i++) ...[
                  _AcademyFinanceCard(
                    summary: academyFinances[i],
                    formatAmount: _formatAmount,
                  ),
                  if (i < academyFinances.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
        ],
      ],
    );
  }
}

class _PersonalFinanceCard extends StatelessWidget {
  final PersonalFinanceSummary summary;
  final String Function(String symbol, double amount) formatAmount;

  const _PersonalFinanceCard({
    required this.summary,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: const Key('coach_personal_finance_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Personal Coaching Finance',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${summary.completedPaidSessions} paid sessions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FinanceStat(
                  label: 'This Month Earnings',
                  value: formatAmount(
                    summary.currencySymbol,
                    summary.thisMonthEarnings,
                  ),
                  valueColor: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FinanceStat(
                  label: 'Pending Payout',
                  value: formatAmount(
                    summary.currencySymbol,
                    summary.pendingPayout,
                  ),
                  valueColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademyFinanceCard extends StatelessWidget {
  final AcademyFinanceSummary summary;
  final String Function(String symbol, double amount) formatAmount;

  const _AcademyFinanceCard({
    required this.summary,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: Key(
        'coach_academy_finance_${summary.academyId}_${summary.branchId ?? 'all'}',
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    summary.payoutModelLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.academyName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (summary.branchName != null)
            Text(
              'Branch: ${summary.branchName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FinanceStat(
                  label: 'Permitted Payout (Month)',
                  value: formatAmount(
                    summary.currencySymbol,
                    summary.permittedPayoutThisMonth,
                  ),
                  valueColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FinanceStat(
                  label: 'Pending Disbursement',
                  value: formatAmount(
                    summary.currencySymbol,
                    summary.pendingDisbursement,
                  ),
                  valueColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _FinanceStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
