import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';

/// DTO for [RefereeProfile] API serialization.
class RefereeProfileModel {
  final String refereeId;
  final String tournamentId;
  final String tournamentName;
  final String venueName;
  final String refereeName;
  final String refereeEmail;
  final String certificationLevel;
  final bool isActive;

  const RefereeProfileModel({
    required this.refereeId,
    required this.tournamentId,
    required this.tournamentName,
    required this.venueName,
    required this.refereeName,
    required this.refereeEmail,
    required this.certificationLevel,
    required this.isActive,
  });

  factory RefereeProfileModel.fromJson(Map<String, dynamic> json) {
    return RefereeProfileModel(
      refereeId: json['refereeId'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      tournamentName: json['tournamentName'] as String? ?? '',
      venueName: json['venueName'] as String? ?? '',
      refereeName: json['refereeName'] as String? ?? '',
      refereeEmail: json['refereeEmail'] as String? ?? '',
      certificationLevel:
          json['certificationLevel'] as String? ?? 'Certified Referee',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  RefereeProfile toEntity() {
    return RefereeProfile(
      refereeId: refereeId,
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      venueName: venueName,
      refereeName: refereeName,
      refereeEmail: refereeEmail,
      certificationLevel: certificationLevel,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'refereeId': refereeId,
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'venueName': venueName,
        'refereeName': refereeName,
        'refereeEmail': refereeEmail,
        'certificationLevel': certificationLevel,
        'isActive': isActive,
      };
}
