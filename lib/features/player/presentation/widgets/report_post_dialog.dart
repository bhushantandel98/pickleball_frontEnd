import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';

/// Modal dialog allowing players to report inappropriate community content
/// according to community guidelines and moderation policies.
class ReportPostDialog extends StatefulWidget {
  final String postId;
  final void Function(CommunityReportReason reason, String? notes) onReport;

  const ReportPostDialog({
    super.key,
    required this.postId,
    required this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required void Function(CommunityReportReason reason, String? notes) onReport,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReportPostDialog(
        postId: postId,
        onReport: onReport,
      ),
    );
  }

  @override
  State<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<ReportPostDialog> {
  CommunityReportReason _selectedReason = CommunityReportReason.inappropriateMedia;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return AlertDialog(
      title: const Text('Report Content'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us understand what is wrong with this post. All reports are confidential.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryColor,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select a reason:',
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RadioGroup<CommunityReportReason>(
              groupValue: _selectedReason,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedReason = val);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CommunityReportReason.values.map((reason) {
                  return RadioListTile<CommunityReportReason>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.error,
                    title: Text(reason.label),
                    value: reason,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _notesController,
              label: 'Additional details (optional)',
              hint: 'Provide extra context if helpful',
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        AppButton.outline(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.destructive(
          label: 'Submit Report',
          onPressed: () {
            final notes = _notesController.text.trim();
            widget.onReport(
              _selectedReason,
              notes.isEmpty ? null : notes,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
