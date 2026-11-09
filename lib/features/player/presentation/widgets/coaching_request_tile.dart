import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

/// Tile displaying an active or historical Academy Enrollment Request.
class AcademyEnrollmentRequestTile extends StatelessWidget {
  final AcademyEnrollmentRequest request;
  final VoidCallback onCancel;

  const AcademyEnrollmentRequestTile({
    super.key,
    required this.request,
    required this.onCancel,
  });

  Widget _buildStatusChip() {
    switch (request.status) {
      case AcademyEnrollmentStatus.pendingApproval:
        return const AppChip.warning(label: 'Pending Academy Approval');
      case AcademyEnrollmentStatus.approved:
        return const AppChip.success(label: 'Enrolled (Approved)');
      case AcademyEnrollmentStatus.waitlisted:
        final pos = request.waitlistPosition != null ? ' (#${request.waitlistPosition})' : '';
        return AppChip.info(label: 'On Waitlist$pos');
      case AcademyEnrollmentStatus.rejected:
        return const AppChip.error(label: 'Application Declined');
      case AcademyEnrollmentStatus.cancelled:
        return const AppChip(label: 'Cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.academyName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      request.branchName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const Divider(height: 20),
          Text(
            request.programTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Batch: ${request.batchName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Schedule: ${request.schedule}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ref: ${request.id}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                dateFormat.format(request.requestedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (request.canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Request'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final confirmed = await AppConfirmationDialog.show(
                    context: context,
                    title: 'Cancel Enrollment Request?',
                    message:
                        'Are you sure you want to cancel your enrollment request for ${request.batchName}?',
                    confirmLabel: 'Cancel Request',
                    isDestructive: true,
                  );
                  if (confirmed == true) {
                    onCancel();
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tile displaying an active or historical Coach Inquiry Request.
class CoachInquiryRequestTile extends StatelessWidget {
  final CoachInquiryRequest inquiry;
  final VoidCallback onCancel;

  const CoachInquiryRequestTile({
    super.key,
    required this.inquiry,
    required this.onCancel,
  });

  Widget _buildStatusChip() {
    switch (inquiry.status) {
      case CoachInquiryStatus.pendingCoachResponse:
        return const AppChip.warning(label: 'Awaiting Coach Review');
      case CoachInquiryStatus.accepted:
        return const AppChip.success(label: 'Inquiry Accepted');
      case CoachInquiryStatus.declined:
        return const AppChip.error(label: 'Coach Unavailable');
      case CoachInquiryStatus.cancelled:
        return const AppChip(label: 'Cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inquiry.coachName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (inquiry.serviceName != null)
                      Text(
                        inquiry.serviceName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const Divider(height: 20),
          Text(
            'Goal: ${inquiry.trainingGoal}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Preferred Times: ${inquiry.preferredDays}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (inquiry.message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${inquiry.message}"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ref: ${inquiry.id}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                dateFormat.format(inquiry.submittedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (inquiry.canCancel) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Inquiry'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  final confirmed = await AppConfirmationDialog.show(
                    context: context,
                    title: 'Cancel Coaching Inquiry?',
                    message:
                        'Are you sure you want to cancel your inquiry to ${inquiry.coachName}?',
                    confirmLabel: 'Cancel Inquiry',
                    isDestructive: true,
                  );
                  if (confirmed == true) {
                    onCancel();
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
