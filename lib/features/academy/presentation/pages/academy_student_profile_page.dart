import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/academy/data/repositories/mock_academy_repository.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';

/// Dedicated Student Profile page with Details & Performance & Progress tabs.
class AcademyStudentProfilePage extends StatelessWidget {
  final String studentId;
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyStudentProfilePage({
    super.key,
    required this.studentId,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<AcademyCubit>.value(
        value: cubit!,
        child: _StudentProfileView(studentId: studentId, academyId: academyId),
      );
    }

    try {
      final existing = context.read<AcademyCubit>();
      return BlocProvider<AcademyCubit>.value(
        value: existing,
        child: _StudentProfileView(studentId: studentId, academyId: academyId),
      );
    } catch (_) {
      return BlocProvider<AcademyCubit>(
        create: (_) => sl.isRegistered<AcademyCubit>()
            ? sl<AcademyCubit>()
            : AcademyCubit(repository: MockAcademyRepository()),
        child: _StudentProfileView(studentId: studentId, academyId: academyId),
      );
    }
  }
}

class _StudentProfileView extends StatefulWidget {
  final String studentId;
  final String academyId;

  const _StudentProfileView({
    required this.studentId,
    required this.academyId,
  });

  @override
  State<_StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<_StudentProfileView> {
  (bool, String?) _resolveRoleScope() {
    try {
      final session = context.read<SessionCubit>().state;
      final isStaff = session.activeRole == UserRole.academyStaff;
      return (!isStaff, session.userId);
    } catch (_) {
      return (true, null);
    }
  }

  void _reloadWorkspace() {
    final (isAdmin, staffUserId) = _resolveRoleScope();
    context.read<AcademyCubit>().loadWorkspace(
          academyId: widget.academyId,
          isAdmin: isAdmin,
          staffUserId: staffUserId,
        );
  }

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AcademyCubit>();
    if (cubit.state is AcademyInitial) {
      _reloadWorkspace();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcademyCubit, AcademyState>(
      listener: (context, state) {
        if (state is AcademyLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor: state.isErrorFeedback
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
          context.read<AcademyCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        if (state is AcademyInitial || state is AcademyLoading) {
          return const Scaffold(
            appBar: CommonAppBar(title: 'Player Profile'),
            body: LoadingView(message: 'Loading player profile...'),
          );
        }

        if (state is AcademyFailure) {
          return Scaffold(
            appBar: const CommonAppBar(title: 'Player Profile'),
            body: ErrorStateView(
              title: 'Unable to load player profile',
              message: state.failure.message,
              onRetry: _reloadWorkspace,
            ),
          );
        }

        final loaded = state as AcademyLoaded;
        final student = loaded.scopedStudents
            .where((s) => s.id == widget.studentId)
            .firstOrNull;

        if (student == null || !loaded.canViewStudents) {
          return const Scaffold(
            appBar: CommonAppBar(title: 'Player Profile'),
            body: EmptyStateView(
              icon: Icon(Icons.person_off_outlined),
              title: 'Student Not Available',
              message:
                  'This student profile could not be found in your authorized branch scope.',
            ),
          );
        }

        final theme = Theme.of(context);
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(student.name),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Performance & Progress'),
                ],
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          child: Text(student.name[0]),
                        ),
                        const SizedBox(width: AppSpacing.md),
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
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DetailsTab(student: student),
                      _PerformanceTab(
                        state: loaded,
                        student: student,
                        onRecordAssessment: loaded.canRecordAssessment
                            ? () => _showAssessmentDialog(
                                  context,
                                  loaded,
                                  student,
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAssessmentDialog(
    BuildContext context,
    AcademyLoaded state,
    AcademyStudent student,
  ) async {
    final cubit = context.read<AcademyCubit>();
    final aspects = state.data.performanceAspects;
    if (aspects.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    final focusCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();
    final ratings = <String, int>{
      for (final aspect in aspects) aspect.id: 7,
    };

    final studentBatch = state.data.batches
        .where((b) => b.id == student.batchId)
        .firstOrNull;
    final approvedCoaches = state.data.coachAffiliations.where((c) {
      if (c.status != CoachAffiliationStatus.accepted) return false;
      if (!c.assignedBranchIds.contains(student.branchId)) return false;
      return c.coachId == student.assignedCoachId ||
          c.coachId == studentBatch?.assignedCoachId;
    }).toList();
    if (approvedCoaches.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No approved coach is assigned to this student\'s batch or branch.',
            ),
          ),
        );
      return;
    }
    var selectedCoachId = approvedCoaches.first.coachId;
    var selectedCoachName = approvedCoaches.first.coachName;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Performance Assessment'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (approvedCoaches.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: approvedCoaches
                                .any((c) => c.coachId == selectedCoachId)
                            ? selectedCoachId
                            : approvedCoaches.first.coachId,
                        decoration: const InputDecoration(
                          labelText: 'Assessing Coach',
                          border: OutlineInputBorder(),
                        ),
                        items: approvedCoaches
                            .map((c) => DropdownMenuItem(
                                  value: c.coachId,
                                  child: Text(c.coachName),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final match = approvedCoaches
                              .firstWhere((c) => c.coachId == v);
                          setDialogState(() {
                            selectedCoachId = match.coachId;
                            selectedCoachName = match.coachName;
                          });
                        },
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: focusCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Focus Area *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: feedbackCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Coach Feedback *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Performance Aspects (Scale 1–10)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...aspects.map((aspect) {
                      final val = ratings[aspect.id] ?? 7;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${aspect.label} (${aspect.category})'),
                              Text(
                                '$val / 10',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            min: 1,
                            max: 10,
                            divisions: 9,
                            value: val.toDouble(),
                            label: '$val',
                            onChanged: (d) => setDialogState(
                              () => ratings[aspect.id] = d.round(),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await cubit.recordStudentAssessment(
                  studentId: student.id,
                  coachId: selectedCoachId,
                  coachName: selectedCoachName,
                  focusArea: focusCtrl.text,
                  aspectRatings: ratings,
                  feedback: feedbackCtrl.text,
                );
                if (ok && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final AcademyStudent student;

  const _DetailsTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Personal & Assignment Info',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppChip.neutral(label: 'Academy-Entered'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(label: 'Phone', value: student.phone),
              _DetailRow(label: 'Email', value: student.email),
              _DetailRow(label: 'Age Group', value: student.ageGroup),
              _DetailRow(label: 'Branch', value: student.branchName),
              _DetailRow(label: 'Batch', value: student.batchName),
              _DetailRow(
                label: 'Assigned Coach',
                value: student.assignedCoachName ?? 'Unassigned',
              ),
              _DetailRow(label: 'Joined', value: df.format(student.joinedAt)),
              if (student.academyNotes != null &&
                  student.academyNotes!.isNotEmpty)
                _DetailRow(label: 'Notes', value: student.academyNotes!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enrollment & Payment Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: 'Enrollment',
                value: student.enrollmentStatus.label,
              ),
              _DetailRow(
                label: 'Payment Status',
                value:
                    '${student.paymentStatus.label} (₹${student.monthlyFeeInr.toStringAsFixed(0)}/mo)',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (student.attendanceHistory.isEmpty)
                const Text('No attendance records yet.')
              else
                ...student.attendanceHistory.map(
                  (att) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceTab extends StatelessWidget {
  final AcademyLoaded state;
  final AcademyStudent student;
  final VoidCallback? onRecordAssessment;

  const _PerformanceTab({
    required this.state,
    required this.student,
    this.onRecordAssessment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM yyyy');
    final assessments = [...student.coachAssessments]
      ..sort((a, b) => b.date.compareTo(a.date));
    final latest = assessments.isNotEmpty ? assessments.first : null;
    final previous = assessments.length > 1 ? assessments[1] : null;
    final overallDelta = (latest != null && previous != null)
        ? latest.overallRating - previous.overallRating
        : null;

    final aspects = state.data.performanceAspects;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Overall Performance',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppChip.info(label: 'Coach-Recorded'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (latest == null)
                      const Text('No evaluations recorded yet.')
                    else
                      Row(
                        children: [
                          Text(
                            '${latest.overallRating.toStringAsFixed(1)} / 10',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (overallDelta != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${overallDelta >= 0 ? '+' : ''}${overallDelta.toStringAsFixed(1)} vs previous',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: overallDelta >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              if (onRecordAssessment != null)
                FilledButton.icon(
                  onPressed: onRecordAssessment,
                  icon: const Icon(Icons.add_chart, size: 18),
                  label: const Text('Assess'),
                ),
            ],
          ),
        ),
        if (latest != null && aspects.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aspect Ratings (Latest Evaluation)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...aspects.map((aspect) {
                  final score = latest.aspectRatings[aspect.id];
                  if (score == null) return const SizedBox.shrink();
                  final prevScore = previous?.aspectRatings[aspect.id];
                  final delta = prevScore != null ? score - prevScore : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${aspect.label} (${aspect.category})',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '$score/10${delta != null ? ' (${delta >= 0 ? '+' : ''}$delta)' : ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: delta == null
                                    ? AppColors.primary
                                    : (delta >= 0
                                        ? AppColors.success
                                        : AppColors.error),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: (score / 10).clamp(0.0, 1.0),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Assessment History (${assessments.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (assessments.isEmpty)
          const AppCard(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('No assessment history available.'),
          )
        else
          ...assessments.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.focusArea,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${item.overallRating.toStringAsFixed(1)} / 10',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.feedback, style: theme.textTheme.bodySmall),
                    if (item.aspectRatings.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: item.aspectRatings.entries.map((entry) {
                          final aspectLabel = aspects
                                  .where((a) => a.id == entry.key)
                                  .firstOrNull
                                  ?.label ??
                              entry.key;
                          return AppChip.neutral(
                            label: '$aspectLabel: ${entry.value}/10',
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Coach: ${item.coachName} • ${df.format(item.date)}',
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
