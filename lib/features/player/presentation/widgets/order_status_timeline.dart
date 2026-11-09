import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Stepper timeline widget visualizing order delivery progress from placement to delivery or cancellation.
class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatusStep> steps;

  const OrderStatusTimeline({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildStepRow(context, theme, timeFormat, steps[i], isLast: i == steps.length - 1),
        ],
      ],
    );
  }

  Widget _buildStepRow(
    BuildContext context,
    ThemeData theme,
    DateFormat timeFormat,
    OrderStatusStep step, {
    required bool isLast,
  }) {
    Color nodeColor;
    IconData nodeIcon;

    if (step.isCompleted) {
      nodeColor = theme.colorScheme.primary;
      nodeIcon = Icons.check_circle;
    } else if (step.isCurrent) {
      nodeColor = Colors.orange.shade700;
      nodeIcon = Icons.radio_button_checked;
    } else {
      nodeColor = theme.colorScheme.outlineVariant;
      nodeIcon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator column with connecting line
          Column(
            children: [
              Icon(nodeIcon, size: 20, color: nodeColor),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Step text info
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: step.isCurrent || step.isCompleted
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: step.isCurrent || step.isCompleted
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                      if (step.timestamp != null)
                        Text(
                          timeFormat.format(step.timestamp!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
