import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_registration_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_registration_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_category_card.dart';

/// Screen managing tournament division entry, team details, waiver consents, and registration confirmation.
class TournamentRegistrationPage extends StatefulWidget {
  final String tournamentId;
  final String? initialCategoryId;
  final TournamentRegistrationCubit? cubit;

  const TournamentRegistrationPage({
    super.key,
    required this.tournamentId,
    this.initialCategoryId,
    this.cubit,
  });

  @override
  State<TournamentRegistrationPage> createState() =>
      _TournamentRegistrationPageState();
}

class _TournamentRegistrationPageState extends State<TournamentRegistrationPage> {
  late final TournamentRegistrationCubit _cubit;
  bool _isLoadingTournament = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ??
        TournamentRegistrationCubit(repository: sl<TournamentRepository>());
    if (_cubit.state is TournamentRegistrationReady) {
      _isLoadingTournament = false;
    } else {
      _loadTournamentAndInit();
    }
  }

  Future<void> _loadTournamentAndInit() async {
    final result = await _cubit.repository.getTournamentById(widget.tournamentId);

    if (!mounted) return;

    switch (result) {
      case Success<TournamentItem>(:final data):
        // Pick initial category: either matching initialCategoryId or first open category
        final initialCat = widget.initialCategoryId != null
            ? data.categories
                .firstWhere((c) => c.id == widget.initialCategoryId, orElse: () => data.categories.first)
            : data.categories.first;

        _cubit.init(
          tournament: data,
          initialCategory: initialCat,
        );

        setState(() {
          _isLoadingTournament = false;
        });
      case FailureResult(:final failure):
        setState(() {
          _isLoadingTournament = false;
          _errorMessage = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTournament) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CommonAppBar(
            title: 'Tournament Registration',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        body: const LoadingView(message: 'Loading tournament details...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CommonAppBar(
            title: 'Tournament Registration',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        body: ErrorStateView(
          title: 'Registration Unavailable',
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _isLoadingTournament = true;
              _errorMessage = null;
            });
            _loadTournamentAndInit();
          },
        ),
      );
    }

    return BlocProvider<TournamentRegistrationCubit>.value(
      value: _cubit,
      child: const _TournamentRegistrationView(),
    );
  }
}

class _TournamentRegistrationView extends StatefulWidget {
  const _TournamentRegistrationView();

  @override
  State<_TournamentRegistrationView> createState() =>
      _TournamentRegistrationViewState();
}

class _TournamentRegistrationViewState
    extends State<_TournamentRegistrationView> {
  late final TextEditingController _partnerController;
  late final TextEditingController _partnerPhoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  static const List<String> tshirtSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _partnerController = TextEditingController();
    _partnerPhoneController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _partnerController.dispose();
    _partnerPhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CommonAppBar(
          title: 'Tournament Registration',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: BlocConsumer<TournamentRegistrationCubit, TournamentRegistrationState>(
        listener: (context, state) {
          if (state is TournamentRegistrationSuccess) {
            context.pushReplacement(
              AppRoutes.playerTournamentConfirmationPath(state.registration.tournamentId),
              extra: state.registration,
            );
          } else if (state is TournamentRegistrationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TournamentRegistrationSuccess) {
            return const SizedBox.shrink();
          }
          if (state is! TournamentRegistrationReady) {
            return const LoadingView(message: 'Preparing registration form...');
          }

          final tournament = state.tournament;
          final category = state.selectedCategory;

          return Column(
            children: [
              Expanded(
                child: ResponsiveContainer(
                  maxWidth: AppSpacing.maxContentWidth,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Summary Card
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tournament.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tournament.venueName} • ${tournament.formattedDateRange}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Section 1: Select Category
                        Text(
                          '1. Select Division / Category',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...tournament.categories.map((cat) {
                          final isSelected = cat.id == category.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: TournamentCategoryCard(
                              key: Key('select_category_${cat.id}'),
                              category: cat,
                              isSelected: isSelected,
                              isSelectable: true,
                              onSelect: () {
                                context
                                    .read<TournamentRegistrationCubit>()
                                    .selectCategory(cat);
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: AppSpacing.md),

                        // Section 2: Player Information (Pre-filled)
                        Text(
                          '2. Player Information',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    state.playerName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'DUPR ${state.playerRating}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${state.playerPhone} • ${state.playerEmail}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Section 3: Partner Details (Doubles only)
                        if (state.isDoubles) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '3. Partner Information',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  key: const Key('registration_partner_name_input'),
                                  controller: _partnerController,
                                  label: 'Partner Full Name *',
                                  hint: 'Enter your doubles partner name',
                                  validator: (_) => state.errors['partnerName'],
                                  autovalidateMode: AutovalidateMode.always,
                                  onChanged: (val) {
                                    context
                                        .read<TournamentRegistrationCubit>()
                                        .updatePartnerName(val);
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppTextField(
                                  key: const Key('registration_partner_phone_input'),
                                  controller: _partnerPhoneController,
                                  label: 'Partner Phone Number (Optional)',
                                  hint: '+91 98765 43210',
                                  keyboardType: TextInputType.phone,
                                  onChanged: (val) {
                                    context
                                        .read<TournamentRegistrationCubit>()
                                        .updatePartnerPhone(val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.md),

                        // Section 4: Tournament Shirt Size
                        Text(
                          state.isDoubles
                              ? '4. Tournament Merchandise'
                              : '3. Tournament Merchandise',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Official T-Shirt Size',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: 8,
                                children: tshirtSizes.map((size) {
                                  final isSelected = state.tshirtSize == size;
                                  return ChoiceChip(
                                    label: Text(size),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        context
                                            .read<TournamentRegistrationCubit>()
                                            .updateTshirtSize(size);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Section 5: Waivers & Agreements
                        Text(
                          state.isDoubles
                              ? '5. Waivers & Acknowledgment'
                              : '4. Waivers & Acknowledgment',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                key: const Key('registration_waiver_checkbox'),
                                value: state.acceptedWaiver,
                                title: Text(
                                  'I accept the tournament liability waiver and consent to sports injury disclaimer.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                subtitle: state.errors['waiver'] != null
                                    ? Text(
                                        state.errors['waiver']!,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 11,
                                        ),
                                      )
                                    : null,
                                onChanged: (val) {
                                  context
                                      .read<TournamentRegistrationCubit>()
                                      .toggleWaiver(val ?? false);
                                },
                              ),
                              CheckboxListTile(
                                key: const Key('registration_rules_checkbox'),
                                value: state.acceptedRules,
                                title: Text(
                                  'I have read and agree to official tournament rules and withdrawal policies.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                subtitle: state.errors['rules'] != null
                                    ? Text(
                                        state.errors['rules']!,
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 11,
                                        ),
                                      )
                                    : null,
                                onChanged: (val) {
                                  context
                                      .read<TournamentRegistrationCubit>()
                                      .toggleRules(val ?? false);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Pricing Breakdown Card
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment & Entry Fee Breakdown',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${category.name} Entry',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    category.formattedFee,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Platform Processing Charge',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '₹0',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Payable',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    category.formattedFee,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: AppSpacing.borderRadiusSm,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Payment Method: Pay at Tournament Desk upon match-day check-in.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),

              // Sticky Submit Button
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: SafeArea(
                  child: AppButton.primary(
                    key: const Key('tournament_confirm_registration_button'),
                    label: category.isCapacityFull
                        ? 'Join Category Waitlist'
                        : 'Confirm Registration (${category.formattedFee})',
                    icon: const Icon(Icons.check_circle_outline),
                    width: double.infinity,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            context.read<TournamentRegistrationCubit>().submit();
                          },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
