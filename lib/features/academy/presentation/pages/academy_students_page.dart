import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Shared Academy Students directory & individual student profile viewer.
class AcademyStudentsPage extends StatefulWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyStudentsPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  State<AcademyStudentsPage> createState() => _AcademyStudentsPageState();
}

class _AcademyStudentsPageState extends State<AcademyStudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _batchIdFilter;
  BatchSkillLevel? _skillFilter;
  EnrollmentRequestStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: widget.cubit,
      academyId: widget.academyId,
      title: 'Academy Students',
      subtitle:
          'Search and filter students across branches, batches, skill levels, attendance, and coach-recorded progress.',
      bodyBuilder: (context, state) {
        if (!state.canViewStudents) {
          return const EmptyStateView(
            icon: Icon(Icons.lock_outline),
            title: 'Access Restricted',
            message: 'You do not have permission to view student profiles.',
          );
        }

        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final query = _searchQuery.trim().toLowerCase();

        final students = state.scopedStudents.where((s) {
          if (query.isNotEmpty &&
              !s.name.toLowerCase().contains(query) &&
              !s.phone.toLowerCase().contains(query)) {
            return false;
          }
          if (_batchIdFilter != null && s.batchId != _batchIdFilter) {
            return false;
          }
          if (_skillFilter != null && s.skillLevel != _skillFilter) {
            return false;
          }
          if (_statusFilter != null && s.enrollmentStatus != _statusFilter) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.scopedBranches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _searchController,
              label: 'Search students by name or mobile',
              hint: 'e.g. Rhea or 98205',
              prefixIcon: const Icon(Icons.search),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _batchIdFilter,
                    decoration: const InputDecoration(
                      labelText: 'Batch',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Batches'),
                      ),
                      ...state.scopedBatches.map(
                        (b) => DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _batchIdFilter = v),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<BatchSkillLevel?>(
                    initialValue: _skillFilter,
                    decoration: const InputDecoration(
                      labelText: 'Skill Level',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<BatchSkillLevel?>(
                        value: null,
                        child: Text('All Levels'),
                      ),
                      ...BatchSkillLevel.values.map(
                        (level) => DropdownMenuItem<BatchSkillLevel?>(
                          value: level,
                          child: Text(level.label),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _skillFilter = v),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<EnrollmentRequestStatus?>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Enrollment Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<EnrollmentRequestStatus?>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      ...EnrollmentRequestStatus.values.map(
                        (status) => DropdownMenuItem<EnrollmentRequestStatus?>(
                          value: status,
                          child: Text(status.label),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (students.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.people_outline),
                title: 'No Students Found',
                message: 'No students match the selected search or filters.',
                actionLabel: 'Clear Filters',
                onAction: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _batchIdFilter = null;
                    _skillFilter = null;
                    _statusFilter = null;
                  });
                  cubit.selectBranch(null);
                },
              )
            else
              ...students.map((student) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    onTap: () => _openStudentProfile(context, student),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(student.name[0]),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${student.branchName} • ${student.batchName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppChip.info(label: student.skillLevel.label),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppChip.neutral(
                              label: student.enrollmentStatus.label,
                            ),
                            AppChip.neutral(
                              label: 'Fee: ${student.paymentStatus.label}',
                            ),
                            if (student.assignedCoachName != null)
                              Text(
                                'Coach: ${student.assignedCoachName}',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _openStudentProfile(
    BuildContext context,
    AcademyStudent student,
  ) async {
    final df = DateFormat('dd MMM yyyy');
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(student.name),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academy-Entered Information
                AppChip.neutral(label: 'Academy-Entered Information'),
                const SizedBox(height: AppSpacing.xs),
                Text('Phone: ${student.phone}'),
                Text('Email: ${student.email}'),
                Text('Age Group: ${student.ageGroup}'),
                Text('Branch: ${student.branchName}'),
                Text('Batch: ${student.batchName} (${student.skillLevel.label})'),
                Text('Assigned Coach: ${student.assignedCoachName ?? 'Unassigned'}'),
                Text('Enrollment Status: ${student.enrollmentStatus.label}'),
                Text(
                  'Payment Status: ${student.paymentStatus.label} (₹${student.monthlyFeeInr.toStringAsFixed(0)}/mo)',
                ),
                Text('Joined: ${df.format(student.joinedAt)}'),
                if (student.academyNotes != null &&
                    student.academyNotes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Academy Notes: ${student.academyNotes}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const Divider(height: AppSpacing.lg),

                // Attendance History
                Text(
                  'Attendance History',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (student.attendanceHistory.isEmpty)
                  const Text('No attendance records yet.')
                else
                  ...student.attendanceHistory.map(
                    (att) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${df.format(att.date)} • ${att.batchName}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            att.status,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: att.status == 'Present'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: AppSpacing.lg),

                // Coach-Recorded Performance Assessments & Feedback
                Row(
                  children: [
                    Text(
                      'Performance & Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppChip.info(label: 'Coach-Recorded'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (student.coachAssessments.isEmpty)
                  const Text('No coach-recorded assessments yet.')
                else
                  ...student.coachAssessments.map(
                    (assess) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    assess.focusArea,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${assess.progressScore}%',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (assess.progressScore / 100).clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              assess.feedback,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recorded by Coach ${assess.coachName} • ${df.format(assess.date)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
