import 'dart:math';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';

/// In-memory mock repository implementing the Player Academy & Coach Discovery operations.
class MockCoachingAcademyRepository implements CoachingAcademyRepository {
  final bool shouldFail;
  final bool isEmpty;

  List<AcademyBranch>? customBranches;
  List<CoachItem>? customCoaches;
  List<AcademyEnrollmentRequest>? customEnrollmentRequests;
  List<CoachInquiryRequest>? customCoachInquiries;

  MockCoachingAcademyRepository({
    this.shouldFail = false,
    this.isEmpty = false,
    this.customBranches,
    this.customCoaches,
    this.customEnrollmentRequests,
    this.customCoachInquiries,
  });

  static List<AcademyBranch> createDefaultBranches() {
    return [
      const AcademyBranch(
        id: 'acad_branch_001',
        academyId: 'acad_001',
        academyName: 'Pinnacle Sports Pickleball Academy',
        branchName: 'Worli Sea Face Campus',
        city: 'Mumbai',
        address: 'Plot 42, Dr. Annie Besant Road, Worli Sea Face, Mumbai 400018',
        operatingHours: 'Mon-Sat: 6:00 AM - 9:00 PM, Sun: 7:00 AM - 1:00 PM',
        contactPhone: '+91 98200 12345',
        contactEmail: 'worli@pinnaclesports.in',
        overview:
            'Premier training academy featuring 6 tournament-grade acrylic courts, '
            'high-speed ball machines, video capture, and certified national coaches.',
        headCoachName: 'Coach Vikram Seth',
        courtCount: 6,
        programs: [
          AcademyProgram(
            id: 'prog_001',
            title: 'Junior High-Performance Development Clinic',
            description:
                'Structured training regimen covering third-shot drop fundamentals, dink patience, '
                'footwork agility, and match strategy for competitive juniors.',
            skillLevel: 'Intermediate to Advanced (DUPR 3.0 - 4.5)',
            ageGroup: 'Junior (U-18)',
            batches: [
              AcademyBatch(
                id: 'batch_001',
                programId: 'prog_001',
                name: 'Morning Performance Batch A',
                schedule: 'Tue, Thu, Sat: 7:00 AM - 8:30 AM',
                maxCapacity: 12,
                enrolledCount: 8,
                isWaitlistEnabled: true,
                waitlistCount: 0,
                instructorName: 'Coach Vikram Seth',
              ),
              AcademyBatch(
                id: 'batch_002',
                programId: 'prog_001',
                name: 'Weekend Elite Squad (Full — Waitlist Open)',
                schedule: 'Sat & Sun: 4:00 PM - 6:00 PM',
                maxCapacity: 10,
                enrolledCount: 10,
                isWaitlistEnabled: true,
                waitlistCount: 3,
                instructorName: 'Coach Vikram Seth',
              ),
            ],
          ),
          AcademyProgram(
            id: 'prog_002',
            title: 'Adult Tactical Mastery & Match Play',
            description:
                'Targeted drill sessions focused on transition zone resets, kitchen line hand speed, '
                'stacking mechanics, and partner chemistry.',
            skillLevel: 'Intermediate (DUPR 3.0 - 4.0)',
            ageGroup: 'Adults (18+)',
            batches: [
              AcademyBatch(
                id: 'batch_003',
                programId: 'prog_002',
                name: 'Evening Pro Batch',
                schedule: 'Mon, Wed, Fri: 7:30 PM - 9:00 PM',
                maxCapacity: 12,
                enrolledCount: 6,
                isWaitlistEnabled: false,
                waitlistCount: 0,
                instructorName: 'Coach Ananya Verma',
              ),
            ],
          ),
        ],
      ),
      const AcademyBranch(
        id: 'acad_branch_002',
        academyId: 'acad_002',
        academyName: 'Dink & Smash Academy Hub',
        branchName: 'Bandra West Branch',
        city: 'Mumbai',
        address: '14th Road, Off Linking Road, Bandra West, Mumbai 400050',
        operatingHours: 'Mon-Sun: 6:00 AM - 10:00 PM',
        contactPhone: '+91 98111 23456',
        contactEmail: 'bandra@dinksmash.in',
        overview:
            'Boutique urban pickleball academy known for beginner-to-intermediate player development, '
            'recreational clinic ladders, and technique foundations.',
        headCoachName: 'Coach Priya Sharma',
        courtCount: 4,
        programs: [
          AcademyProgram(
            id: 'prog_003',
            title: 'Adult Beginner Foundations & Fundamentals',
            description:
                'Complete entry course covering continental grip, rules, scoring, serve technique, '
                'non-volley zone guidelines, and sustained dinking.',
            skillLevel: 'Beginner (DUPR 2.0 - 2.9)',
            ageGroup: 'Adults (18+)',
            batches: [
              AcademyBatch(
                id: 'batch_004',
                programId: 'prog_003',
                name: 'Weekday Morning Cohort',
                schedule: 'Mon, Wed, Fri: 8:00 AM - 9:30 AM',
                maxCapacity: 8,
                enrolledCount: 5,
                isWaitlistEnabled: true,
                waitlistCount: 0,
                instructorName: 'Coach Priya Sharma',
              ),
              AcademyBatch(
                id: 'batch_005',
                programId: 'prog_003',
                name: 'Weekend Evening Cohort (Full — Closed)',
                schedule: 'Sat & Sun: 6:00 PM - 7:30 PM',
                maxCapacity: 8,
                enrolledCount: 8,
                isWaitlistEnabled: false,
                waitlistCount: 0,
                instructorName: 'Coach Rajesh Patel',
              ),
            ],
          ),
          AcademyProgram(
            id: 'prog_004',
            title: 'Doubles Tactical Positioning Workshop',
            description:
                'Focus on court geometry, target selection, poaching, defense against bangers, '
                'and live point simulation.',
            skillLevel: 'Intermediate (DUPR 3.0 - 3.9)',
            ageGroup: 'All Ages',
            batches: [
              AcademyBatch(
                id: 'batch_006',
                programId: 'prog_004',
                name: 'Sunday Intensive Batch',
                schedule: 'Sun: 9:00 AM - 12:00 PM',
                maxCapacity: 12,
                enrolledCount: 7,
                isWaitlistEnabled: true,
                waitlistCount: 0,
                instructorName: 'Coach Priya Sharma',
              ),
            ],
          ),
        ],
      ),
      const AcademyBranch(
        id: 'acad_branch_003',
        academyId: 'acad_003',
        academyName: 'Ace Point Pickleball Academy',
        branchName: 'Andheri East Campus',
        city: 'Mumbai',
        address: 'Saki Vihar Road, Near Metro Station, Andheri East, Mumbai 400072',
        operatingHours: 'Mon-Sat: 6:30 AM - 9:30 PM, Sun: Closed',
        contactPhone: '+91 98333 45678',
        contactEmail: 'andheri@acepoint.in',
        overview:
            'State-of-the-art climate-controlled indoor pickleball academy providing '
            'year-round coaching and tournament preparation programs.',
        headCoachName: 'Coach David Miller',
        courtCount: 5,
        programs: [
          AcademyProgram(
            id: 'prog_005',
            title: 'Tournament Preparation & Conditioning',
            description:
                'Rigorous tournament preparation covering pressure point play, match psychology, '
                'scouting adjustments, and conditioning.',
            skillLevel: 'Advanced (DUPR 4.0+)',
            ageGroup: 'Open',
            batches: [
              AcademyBatch(
                id: 'batch_007',
                programId: 'prog_005',
                name: 'Tournament Ready Batch',
                schedule: 'Tue, Thu, Sat: 6:00 PM - 7:30 PM',
                maxCapacity: 8,
                enrolledCount: 4,
                isWaitlistEnabled: true,
                waitlistCount: 0,
                instructorName: 'Coach David Miller',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static List<CoachItem> createDefaultCoaches() {
    return [
      const CoachItem(
        id: 'coach_001',
        name: 'Coach David Miller',
        title: 'Head Performance Coach & USAPA Pro',
        bio:
            'Former competitive tennis pro turned elite pickleball coach with 8+ years of dedicated coaching experience. '
            'Specializes in third-shot drops, kitchen discipline, and high-pressure tournament match execution.',
        rating: 4.9,
        reviewCount: 52,
        city: 'Mumbai',
        experienceYears: 8,
        certifications: [
          'PPR Certified Professional Coach',
          'IPTPA Level 2 Instructor',
          'USAPA Certified Tournament Coach',
        ],
        specializations: [
          'Third-Shot Drop & Reset Mechanics',
          'Kitchen Line Hand Speed & Reflexes',
          'Tournament Match Strategy & Game Planning',
          'Advanced Doubles Communication',
        ],
        services: [
          CoachService(
            id: 'srv_001',
            name: '1-on-1 Private Performance Coaching',
            description:
                'Intensive individual session tailored to your mechanics, video stroke breakdown, and match weakness correction.',
            duration: '60 Min',
            fee: 1500.0,
            feeDisplay: '₹1,500 / hr',
          ),
          CoachService(
            id: 'srv_002',
            name: 'Semi-Private 2-on-1 Doubles Chemistry',
            description:
                'Dedicated session for regular tournament partners focusing on stacking, court coverage, and switch communication.',
            duration: '90 Min',
            fee: 2200.0,
            feeDisplay: '₹2,200 / session',
          ),
          CoachService(
            id: 'srv_003',
            name: 'Video Analysis & Game Strategy Breakdown',
            description:
                'Recorded match playback session identifying unforced errors, shot selection patterns, and positioning flaws.',
            duration: '45 Min',
            fee: 1200.0,
            feeDisplay: '₹1,200 / review',
          ),
        ],
        affiliations: [
          'Ace Point Pickleball Academy',
          'Grand Slam Pickleball Arena',
        ],
        availabilitySchedule: 'Mon, Wed, Fri: 6:00 AM - 11:00 AM, 4:00 PM - 8:00 PM',
      ),
      const CoachItem(
        id: 'coach_002',
        name: 'Coach Priya Sharma',
        title: 'Senior Development Coach & Junior Specialist',
        bio:
            'Passionate development coach specializing in building rock-solid mechanical foundations, '
            'footwork speed, and patience for both rising juniors and adult beginners.',
        rating: 4.8,
        reviewCount: 38,
        city: 'Mumbai',
        experienceYears: 5,
        certifications: [
          'PPR Certified Associate Coach',
          'Youth Sports Certified Trainer',
        ],
        specializations: [
          'Foundational Stroke Mechanics',
          'Junior Pickleball Development',
          'Serve Consistency & Deep Returns',
          'Footwork Agility & Split-Step Timing',
        ],
        services: [
          CoachService(
            id: 'srv_004',
            name: 'Individual Skill Building (Private)',
            description:
                'Focus on forehand/backhand groundstroke consistency, non-volley zone line safety, and controlled dink drops.',
            duration: '60 Min',
            fee: 1200.0,
            feeDisplay: '₹1,200 / hr',
          ),
          CoachService(
            id: 'srv_005',
            name: 'Small Group Clinic (3-4 Players)',
            description:
                'Dynamic drill stations, live point play, and situational scoring games in a supportive group atmosphere.',
            duration: '90 Min',
            fee: 800.0,
            feeDisplay: '₹800 / player',
          ),
        ],
        affiliations: [
          'Dink & Smash Academy Hub',
          'Sunrise Pickleball Club',
        ],
        availabilitySchedule: 'Tue, Thu, Sat: 7:00 AM - 12:00 PM, 3:00 PM - 7:00 PM',
      ),
      const CoachItem(
        id: 'coach_003',
        name: 'Coach Rajesh Patel',
        title: 'Master Tactician & DUPR Official Evaluator',
        bio:
            'National tournament competitor and certified DUPR rating evaluator. '
            'Helps intermediate players break through skill plateaus from 3.0 to 4.5+ through data-backed drills.',
        rating: 4.9,
        reviewCount: 64,
        city: 'Mumbai',
        experienceYears: 7,
        certifications: [
          'IPTPA Master Teaching Professional',
          'Certified DUPR Rating Evaluator',
        ],
        specializations: [
          'DUPR Skill Assessment & Rating Verification',
          'Defending Against Aggressive Bangers',
          'Erne & ATP Shot Execution',
          'Speed-up vs Dink Discipline',
        ],
        services: [
          CoachService(
            id: 'srv_006',
            name: 'DUPR Benchmark Assessment & Private Lesson',
            description:
                'Comprehensive 24-skill benchmark test, official DUPR rating verification, and targeted mechanical adjustments.',
            duration: '75 Min',
            fee: 1800.0,
            feeDisplay: '₹1,800 / assessment',
          ),
          CoachService(
            id: 'srv_007',
            name: 'Tournament Match Coaching & Warmup',
            description:
                'On-site court preparation, opponent scouting, between-game adjustments, and tactical timeouts.',
            duration: 'Per Match / Tournament',
            fee: 3000.0,
            feeDisplay: '₹3,000 / day',
          ),
        ],
        affiliations: [
          'Pinnacle Sports Academy',
          'Pacific Pickleball Center',
        ],
        availabilitySchedule: 'Mon, Tue, Thu: 8:00 AM - 1:00 PM, 5:00 PM - 9:00 PM',
      ),
      const CoachItem(
        id: 'coach_004',
        name: 'Coach Ananya Verma',
        title: 'Tactical Doubles Specialist & State Champion',
        bio:
            'Current State Women Doubles Champion with 4+ years of competitive coaching. '
            'Specializes in fast-paced transition play, mid-court resets, and court communication.',
        rating: 4.7,
        reviewCount: 29,
        city: 'Mumbai',
        experienceYears: 4,
        certifications: [
          'PPR Certified Coach',
          'State Doubles Gold Medalist 2025',
        ],
        specializations: [
          'Women Doubles Strategy & Stacking',
          'Transition Zone Reset Drops',
          'Aggressive Backhand Roll Dinks',
          'Mental Toughness & Focus',
        ],
        services: [
          CoachService(
            id: 'srv_008',
            name: 'Private Tactical Session',
            description:
                'Tailored high-intensity drills covering paddle preparation, mid-court resets, and offensive rolls.',
            duration: '60 Min',
            fee: 1400.0,
            feeDisplay: '₹1,400 / hr',
          ),
        ],
        affiliations: [
          'Metro Pickleball Complex',
        ],
        availabilitySchedule: 'Wed, Fri, Sun: 6:00 AM - 10:00 AM, 4:00 PM - 7:30 PM',
      ),
    ];
  }

  static List<AcademyEnrollmentRequest> createDefaultEnrollmentRequests() {
    return [
      AcademyEnrollmentRequest(
        id: 'ENR-20261105-1021',
        branchId: 'acad_branch_001',
        branchName: 'Worli Sea Face Campus',
        academyName: 'Pinnacle Sports Pickleball Academy',
        programId: 'prog_001',
        programTitle: 'Junior High-Performance Development Clinic',
        batchId: 'batch_001',
        batchName: 'Morning Performance Batch A',
        schedule: 'Tue, Thu, Sat: 7:00 AM - 8:30 AM',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex.rivera@example.com',
        playerRating: 3.8,
        emergencyContactName: 'Carlos Rivera',
        emergencyContactPhone: '+91 98765 43211',
        notes: 'Looking to prepare for upcoming state tournament.',
        requestedAt: DateTime(2026, 11, 5, 10, 30),
        status: AcademyEnrollmentStatus.pendingApproval,
        isWaitlist: false,
      ),
      AcademyEnrollmentRequest(
        id: 'ENR-20261102-0944',
        branchId: 'acad_branch_001',
        branchName: 'Worli Sea Face Campus',
        academyName: 'Pinnacle Sports Pickleball Academy',
        programId: 'prog_001',
        programTitle: 'Junior High-Performance Development Clinic',
        batchId: 'batch_002',
        batchName: 'Weekend Elite Squad (Full — Waitlist Open)',
        schedule: 'Sat & Sun: 4:00 PM - 6:00 PM',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex.rivera@example.com',
        playerRating: 3.8,
        emergencyContactName: 'Carlos Rivera',
        emergencyContactPhone: '+91 98765 43211',
        requestedAt: DateTime(2026, 11, 2, 14, 15),
        status: AcademyEnrollmentStatus.waitlisted,
        isWaitlist: true,
        waitlistPosition: 3,
      ),
    ];
  }

  static List<CoachInquiryRequest> createDefaultCoachInquiries() {
    return [
      CoachInquiryRequest(
        id: 'INQ-20261106-2041',
        coachId: 'coach_001',
        coachName: 'Coach David Miller',
        serviceId: 'srv_001',
        serviceName: '1-on-1 Private Performance Coaching',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex.rivera@example.com',
        preferredDays: 'Wednesdays or Fridays, 7:00 AM',
        playerRating: 3.8,
        trainingGoal: 'Third-shot drop consistency and transition zone resets',
        message:
            'Hi Coach David, looking to improve my third-shot drop consistency from the baseline '
            'ahead of an upcoming tournament. Available weekday mornings.',
        submittedAt: DateTime(2026, 11, 6, 9, 20),
        status: CoachInquiryStatus.pendingCoachResponse,
      ),
    ];
  }

  void _initCustomData() {
    customBranches ??= createDefaultBranches();
    customCoaches ??= createDefaultCoaches();
    customEnrollmentRequests ??= createDefaultEnrollmentRequests();
    customCoachInquiries ??= createDefaultCoachInquiries();
  }

  @override
  Future<Result<List<AcademyBranch>>> getAcademyBranches({
    String? query,
    String? city,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve academy branches.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();

    var results = List<AcademyBranch>.from(customBranches!);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((b) {
        return b.academyName.toLowerCase().contains(q) ||
            b.branchName.toLowerCase().contains(q) ||
            b.city.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q);
      }).toList();
    }

    if (city != null && city.trim().isNotEmpty && city != 'All Cities') {
      final c = city.trim().toLowerCase();
      results = results.where((b) => b.city.toLowerCase() == c).toList();
    }

    return Success(results);
  }

  @override
  Future<Result<AcademyBranch>> getAcademyBranchById(String branchId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to load academy branch details.'),
      );
    }

    _initCustomData();

    final branch = customBranches!.firstWhere(
      (b) => b.id == branchId,
      orElse: () => const AcademyBranch(
        id: '',
        academyId: '',
        academyName: '',
        branchName: '',
        city: '',
        address: '',
        operatingHours: '',
      ),
    );

    if (branch.id.isEmpty) {
      return const FailureResult(
        NotFoundFailure(message: 'Academy branch not found.'),
      );
    }

    return Success(branch);
  }

  @override
  Future<Result<AcademyEnrollmentRequest>> submitEnrollmentRequest({
    required String branchId,
    required String programId,
    required String batchId,
    required String playerName,
    required String playerPhone,
    String playerEmail = '',
    double? playerRating,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? notes,
    bool isWaitlist = false,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to submit enrollment request.'),
      );
    }

    // Input validation
    if (playerName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Player name is required.'),
      );
    }
    if (playerPhone.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Valid phone number is required.'),
      );
    }
    if (emergencyContactName.trim().isEmpty || emergencyContactPhone.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Emergency contact name and phone number are required.',
        ),
      );
    }

    _initCustomData();

    final branchIndex = customBranches!.indexWhere((b) => b.id == branchId);
    if (branchIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Academy branch not found.'),
      );
    }
    final branch = customBranches![branchIndex];

    final programIndex = branch.programs.indexWhere((p) => p.id == programId);
    if (programIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Academy program not found.'),
      );
    }
    final program = branch.programs[programIndex];

    final batchIndex = program.batches.indexWhere((b) => b.id == batchId);
    if (batchIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Program batch not found.'),
      );
    }
    final batch = program.batches[batchIndex];

    // Enforce business rules:
    // When batch is full, waitlist must only be offered when enabled for the batch.
    if (batch.isFull) {
      if (!batch.isWaitlistEnabled) {
        return const FailureResult(
          ValidationFailure(
            message: 'This batch has reached maximum capacity and the waitlist is closed.',
          ),
        );
      }
      isWaitlist = true;
    }

    // Generate standardized reference
    final now = DateTime.now();
    final randomSuffix = (1000 + Random().nextInt(9000)).toString();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final requestId = 'ENR-$dateStr-$randomSuffix';

    final int? waitlistPos = isWaitlist ? batch.waitlistCount + 1 : null;

    final request = AcademyEnrollmentRequest(
      id: requestId,
      branchId: branch.id,
      branchName: branch.branchName,
      academyName: branch.academyName,
      programId: program.id,
      programTitle: program.title,
      batchId: batch.id,
      batchName: batch.name,
      schedule: batch.schedule,
      playerName: playerName.trim(),
      playerPhone: playerPhone.trim(),
      playerEmail: playerEmail.trim(),
      playerRating: playerRating,
      emergencyContactName: emergencyContactName.trim(),
      emergencyContactPhone: emergencyContactPhone.trim(),
      notes: notes?.trim(),
      requestedAt: now,
      status: isWaitlist
          ? AcademyEnrollmentStatus.waitlisted
          : AcademyEnrollmentStatus.pendingApproval,
      isWaitlist: isWaitlist,
      waitlistPosition: waitlistPos,
    );

    // Update batch in memory if waitlist position incremented
    if (isWaitlist) {
      final updatedBatch = batch.copyWith(waitlistCount: batch.waitlistCount + 1);
      final updatedBatches = List<AcademyBatch>.from(program.batches);
      updatedBatches[batchIndex] = updatedBatch;

      final updatedProgram = AcademyProgram(
        id: program.id,
        title: program.title,
        description: program.description,
        skillLevel: program.skillLevel,
        ageGroup: program.ageGroup,
        batches: updatedBatches,
      );
      final updatedPrograms = List<AcademyProgram>.from(branch.programs);
      updatedPrograms[programIndex] = updatedProgram;

      customBranches![branchIndex] = AcademyBranch(
        id: branch.id,
        academyId: branch.academyId,
        academyName: branch.academyName,
        branchName: branch.branchName,
        city: branch.city,
        address: branch.address,
        operatingHours: branch.operatingHours,
        contactPhone: branch.contactPhone,
        contactEmail: branch.contactEmail,
        overview: branch.overview,
        headCoachName: branch.headCoachName,
        courtCount: branch.courtCount,
        programs: updatedPrograms,
      );
    }

    customEnrollmentRequests!.insert(0, request);
    return Success(request);
  }

  @override
  Future<Result<List<AcademyEnrollmentRequest>>> getMyEnrollmentRequests() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load enrollment requests.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();
    return Success(List<AcademyEnrollmentRequest>.from(customEnrollmentRequests!));
  }

  @override
  Future<Result<AcademyEnrollmentRequest>> cancelEnrollmentRequest(String requestId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to cancel enrollment request.'),
      );
    }

    _initCustomData();

    final index = customEnrollmentRequests!.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Enrollment request not found.'),
      );
    }

    final request = customEnrollmentRequests![index];
    if (!request.canCancel) {
      return FailureResult(
        ValidationFailure(
          message:
              'Cannot cancel this enrollment request with status "${request.status.displayName}".',
        ),
      );
    }

    final updated = request.copyWith(status: AcademyEnrollmentStatus.cancelled);
    customEnrollmentRequests![index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<List<CoachItem>>> getCoaches({
    String? query,
    String? city,
    String? specialization,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve coach directory.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();

    var results = List<CoachItem>.from(customCoaches!);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.specializations.any((s) => s.toLowerCase().contains(q)) ||
            c.affiliations.any((a) => a.toLowerCase().contains(q));
      }).toList();
    }

    if (city != null && city.trim().isNotEmpty && city != 'All Cities') {
      final c = city.trim().toLowerCase();
      results = results.where((coach) => coach.city.toLowerCase() == c).toList();
    }

    if (specialization != null &&
        specialization.trim().isNotEmpty &&
        specialization != 'All Specializations') {
      final s = specialization.trim().toLowerCase();
      results = results.where((coach) {
        return coach.specializations.any((spec) => spec.toLowerCase().contains(s));
      }).toList();
    }

    return Success(results);
  }

  @override
  Future<Result<CoachItem>> getCoachById(String coachId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to retrieve coach details.'),
      );
    }

    _initCustomData();

    final coach = customCoaches!.firstWhere(
      (c) => c.id == coachId,
      orElse: () => const CoachItem(
        id: '',
        name: '',
        title: '',
        bio: '',
        city: '',
        experienceYears: 0,
        availabilitySchedule: '',
      ),
    );

    if (coach.id.isEmpty) {
      return const FailureResult(
        NotFoundFailure(message: 'Coach not found.'),
      );
    }

    return Success(coach);
  }

  @override
  Future<Result<CoachInquiryRequest>> submitCoachInquiry({
    required String coachId,
    String? serviceId,
    required String playerName,
    required String playerPhone,
    String playerEmail = '',
    required String preferredDays,
    double? playerRating,
    required String trainingGoal,
    required String message,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to submit coaching inquiry.'),
      );
    }

    if (playerName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Player name is required.'),
      );
    }
    if (playerPhone.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Player phone number is required.'),
      );
    }
    if (trainingGoal.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Please specify your training goal or focus.'),
      );
    }
    if (message.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Please enter a message for the coach.'),
      );
    }

    _initCustomData();

    final coachIndex = customCoaches!.indexWhere((c) => c.id == coachId);
    if (coachIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Coach not found.'),
      );
    }
    final coach = customCoaches![coachIndex];

    String? serviceName;
    if (serviceId != null) {
      final srv = coach.services.where((s) => s.id == serviceId).firstOrNull;
      serviceName = srv?.name;
    }

    final now = DateTime.now();
    final randomSuffix = (1000 + Random().nextInt(9000)).toString();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final inquiryId = 'INQ-$dateStr-$randomSuffix';

    final inquiry = CoachInquiryRequest(
      id: inquiryId,
      coachId: coach.id,
      coachName: coach.name,
      serviceId: serviceId,
      serviceName: serviceName,
      playerName: playerName.trim(),
      playerPhone: playerPhone.trim(),
      playerEmail: playerEmail.trim(),
      preferredDays: preferredDays.trim(),
      playerRating: playerRating,
      trainingGoal: trainingGoal.trim(),
      message: message.trim(),
      submittedAt: now,
      status: CoachInquiryStatus.pendingCoachResponse,
    );

    customCoachInquiries!.insert(0, inquiry);
    return Success(inquiry);
  }

  @override
  Future<Result<List<CoachInquiryRequest>>> getMyCoachInquiries() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve coaching inquiries.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();
    return Success(List<CoachInquiryRequest>.from(customCoachInquiries!));
  }

  @override
  Future<Result<CoachInquiryRequest>> cancelCoachInquiry(String inquiryId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to cancel coaching inquiry.'),
      );
    }

    _initCustomData();

    final index = customCoachInquiries!.indexWhere((i) => i.id == inquiryId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Coaching inquiry not found.'),
      );
    }

    final inquiry = customCoachInquiries![index];
    if (!inquiry.canCancel) {
      return FailureResult(
        ValidationFailure(
          message:
              'Cannot cancel coaching inquiry with status "${inquiry.status.displayName}".',
        ),
      );
    }

    final updated = inquiry.copyWith(status: CoachInquiryStatus.cancelled);
    customCoachInquiries![index] = updated;
    return Success(updated);
  }
}
