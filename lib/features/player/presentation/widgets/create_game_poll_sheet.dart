import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_dropdown.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_game_poll_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_game_poll_state.dart';

/// Modal sheet enabling players to broadcast a venue-based game-request poll
/// with venue binding, match time preferences, skill level criteria, and custom poll options.
class CreateGamePollSheet extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final double? authorRating;
  final void Function(CommunityPost newPost)? onPollCreated;

  const CreateGamePollSheet({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    this.authorAvatarUrl,
    this.authorRating,
    this.onPollCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    void Function(CommunityPost newPost)? onPollCreated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => CreateGamePollCubit(
          communityRepository: sl<CommunityRepository>(),
          venueRepository: sl<VenueRepository>(),
        )..loadVenues(),
        child: CreateGamePollSheet(
          authorId: authorId,
          authorName: authorName,
          authorHandle: authorHandle,
          authorAvatarUrl: authorAvatarUrl,
          authorRating: authorRating,
          onPollCreated: onPollCreated,
        ),
      ),
    );
  }

  @override
  State<CreateGamePollSheet> createState() => _CreateGamePollSheetState();
}

class _CreateGamePollSheetState extends State<CreateGamePollSheet> {
  final _contentController = TextEditingController();
  VenueItem? _selectedVenue;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '06:00 PM - 08:00 PM';
  String _selectedFormat = 'Doubles (2v2)';
  String _selectedSkillLevel = 'Intermediate (3.0 - 4.0)';

  final List<TextEditingController> _optionControllers = [
    TextEditingController(text: "I'm in! (Doubles)"),
    TextEditingController(text: 'Need a partner'),
    TextEditingController(text: 'Can play 1 hr later'),
  ];

  static const _timeSlots = [
    '06:00 AM - 08:00 AM',
    '08:00 AM - 10:00 AM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
    '08:00 PM - 10:00 PM',
  ];

  static const _formats = [
    'Doubles (2v2)',
    'Singles (1v1)',
    'Mixed Doubles',
    'King of the Court',
  ];

  static const _skillLevels = [
    'Beginner (1.0 - 2.5)',
    'Intermediate (3.0 - 4.0)',
    'Advanced (4.0+)',
    'Open to All',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 5) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final controller = _optionControllers.removeAt(index);
        controller.dispose();
      });
    }
  }

  void _handleSubmit(BuildContext context) {
    if (_selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid venue.')),
      );
      return;
    }

    final options = _optionControllers.map((c) => c.text).toList();

    context.read<CreateGamePollCubit>().submitPoll(
          authorId: widget.authorId,
          authorName: widget.authorName,
          authorHandle: widget.authorHandle,
          authorAvatarUrl: widget.authorAvatarUrl,
          authorRating: widget.authorRating,
          content: _contentController.text,
          venue: _selectedVenue!,
          playDate: _selectedDate,
          timeSlot: _selectedTimeSlot,
          gameFormat: _selectedFormat,
          targetSkillLevel: _selectedSkillLevel,
          optionTexts: options,
        );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<CreateGamePollCubit, CreateGamePollState>(
      listener: (context, state) {
        if (state is CreateGamePollSuccess) {
          widget.onPollCreated?.call(state.post);
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreateGamePollSubmitting;
        final venues = state is CreateGamePollInitial
            ? state.availableVenues
            : (state is CreateGamePollFailure ? state.availableVenues : <VenueItem>[]);

        if (_selectedVenue == null && venues.isNotEmpty) {
          _selectedVenue = venues.first;
        }

        return Container(
          height: mediaQuery.size.height * 0.9,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request a Game (Poll)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form Scroll Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state is CreateGamePollFailure) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.error,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      // Description
                      AppTextField(
                        controller: _contentController,
                        label: 'Game Call-out / Description',
                        hint: 'e.g. Looking for 2 more players for competitive doubles this weekend!',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Venue Dropdown
                      Text(
                        'Select Venue (Required):',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (venues.isEmpty)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<VenueItem>(
                          initialValue: _selectedVenue,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                          items: venues.map((venue) {
                            return DropdownMenuItem<VenueItem>(
                              value: venue,
                              child: Text(
                                venue.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedVenue = val);
                            }
                          },
                        ),
                      const SizedBox(height: AppSpacing.md),

                      // Date & Time Slot
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Play Date:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 30)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat.yMMMd().format(_selectedDate),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Slot:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppDropdown<String>(
                                  value: _selectedTimeSlot,
                                  items: _timeSlots
                                      .map((slot) => DropdownMenuItem<String>(
                                            value: slot,
                                            child: Text(slot),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedTimeSlot = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Game Format & Skill Level
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Game Format:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppDropdown<String>(
                                  value: _selectedFormat,
                                  items: _formats
                                      .map((f) => DropdownMenuItem<String>(
                                            value: f,
                                            child: Text(f),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedFormat = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Skill Level:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppDropdown<String>(
                                  value: _selectedSkillLevel,
                                  items: _skillLevels
                                      .map((s) => DropdownMenuItem<String>(
                                            value: s,
                                            child: Text(s),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(
                                          () => _selectedSkillLevel = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Poll Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Poll Options (Min. 2):',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_optionControllers.length < 5)
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Option'),
                              onPressed: _addOption,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...List.generate(_optionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _optionControllers[index],
                                  hint: 'Option ${index + 1}',
                                ),
                              ),
                              if (_optionControllers.length > 2) ...[
                                const SizedBox(width: AppSpacing.xs),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _removeOption(index),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom Submit Button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton.primary(
                    label: isSubmitting ? 'Creating Poll...' : 'Broadcast Game Request',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : () => _handleSubmit(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
