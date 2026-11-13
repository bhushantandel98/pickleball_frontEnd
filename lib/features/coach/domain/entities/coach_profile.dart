import 'package:equatable/equatable.dart';

/// Represents a coaching certification held by the coach.
/// Note: Credential verification workflows are intentionally omitted per PRD.
class CoachCertification extends Equatable {
  final String id;
  final String name;
  final String issuingBody;
  final String yearObtained;
  final String? details;

  const CoachCertification({
    required this.id,
    required this.name,
    required this.issuingBody,
    required this.yearObtained,
    this.details,
  });

  CoachCertification copyWith({
    String? id,
    String? name,
    String? issuingBody,
    String? yearObtained,
    String? details,
  }) {
    return CoachCertification(
      id: id ?? this.id,
      name: name ?? this.name,
      issuingBody: issuingBody ?? this.issuingBody,
      yearObtained: yearObtained ?? this.yearObtained,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [id, name, issuingBody, yearObtained, details];
}

/// Represents a personal coaching service offering (separate from academy programs).
class CoachServiceOffering extends Equatable {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double fee;
  final String currencySymbol;

  const CoachServiceOffering({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.fee,
    this.currencySymbol = '₹',
  });

  CoachServiceOffering copyWith({
    String? id,
    String? name,
    String? description,
    int? durationMinutes,
    double? fee,
    String? currencySymbol,
  }) {
    return CoachServiceOffering(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      fee: fee ?? this.fee,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        durationMinutes,
        fee,
        currencySymbol,
      ];
}

/// Read-only display item describing general personal coaching availability.
class CoachAvailabilityWindow extends Equatable {
  final String dayLabel;
  final String timeWindow;
  final String locationNote;

  const CoachAvailabilityWindow({
    required this.dayLabel,
    required this.timeWindow,
    required this.locationNote,
  });

  @override
  List<Object?> get props => [dayLabel, timeWindow, locationNote];
}

/// Complete Coach Profile aggregate for personal coaching identity,
/// kept strictly separate from academy-owned affiliations and finances.
class CoachProfile extends Equatable {
  final String coachId;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String bio;
  final String? avatarUrl;

  final int yearsOfExperience;
  final String coachingExperienceSummary;
  final String professionalBackground;

  final List<CoachCertification> certifications;
  final List<String> specializations;
  final List<CoachServiceOffering> services;

  final double defaultHourlyFee;
  final String feeNotes;
  final String currencySymbol;

  final bool isAcceptingPersonalInquiries;
  final List<CoachAvailabilityWindow> availabilityWindows;
  final String availabilityNote;

  const CoachProfile({
    required this.coachId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.bio,
    this.avatarUrl,
    required this.yearsOfExperience,
    required this.coachingExperienceSummary,
    required this.professionalBackground,
    required this.certifications,
    required this.specializations,
    required this.services,
    required this.defaultHourlyFee,
    required this.feeNotes,
    this.currencySymbol = '₹',
    this.isAcceptingPersonalInquiries = true,
    required this.availabilityWindows,
    required this.availabilityNote,
  });

  CoachProfile copyWith({
    String? coachId,
    String? fullName,
    String? phone,
    String? email,
    String? city,
    String? bio,
    String? avatarUrl,
    bool clearAvatar = false,
    int? yearsOfExperience,
    String? coachingExperienceSummary,
    String? professionalBackground,
    List<CoachCertification>? certifications,
    List<String>? specializations,
    List<CoachServiceOffering>? services,
    double? defaultHourlyFee,
    String? feeNotes,
    String? currencySymbol,
    bool? isAcceptingPersonalInquiries,
    List<CoachAvailabilityWindow>? availabilityWindows,
    String? availabilityNote,
  }) {
    return CoachProfile(
      coachId: coachId ?? this.coachId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      coachingExperienceSummary:
          coachingExperienceSummary ?? this.coachingExperienceSummary,
      professionalBackground:
          professionalBackground ?? this.professionalBackground,
      certifications: certifications ?? this.certifications,
      specializations: specializations ?? this.specializations,
      services: services ?? this.services,
      defaultHourlyFee: defaultHourlyFee ?? this.defaultHourlyFee,
      feeNotes: feeNotes ?? this.feeNotes,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isAcceptingPersonalInquiries:
          isAcceptingPersonalInquiries ?? this.isAcceptingPersonalInquiries,
      availabilityWindows: availabilityWindows ?? this.availabilityWindows,
      availabilityNote: availabilityNote ?? this.availabilityNote,
    );
  }

  @override
  List<Object?> get props => [
        coachId,
        fullName,
        phone,
        email,
        city,
        bio,
        avatarUrl,
        yearsOfExperience,
        coachingExperienceSummary,
        professionalBackground,
        certifications,
        specializations,
        services,
        defaultHourlyFee,
        feeNotes,
        currencySymbol,
        isAcceptingPersonalInquiries,
        availabilityWindows,
        availabilityNote,
      ];
}
