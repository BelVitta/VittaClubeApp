import 'package:equatable/equatable.dart';

import 'dependent_enums.dart';

class UsageRecordEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String holderUserId;
  final BeneficiaryType beneficiaryType;
  final String? beneficiaryId;
  final String cycleReference;
  final DateTime usedAt;

  const UsageRecordEntity({
    required this.id,
    required this.appointmentId,
    required this.holderUserId,
    required this.beneficiaryType,
    this.beneficiaryId,
    required this.cycleReference,
    required this.usedAt,
  });

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        holderUserId,
        beneficiaryType,
        beneficiaryId,
        cycleReference,
        usedAt,
      ];
}
