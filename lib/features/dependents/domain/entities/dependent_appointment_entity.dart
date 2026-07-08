import 'package:equatable/equatable.dart';

import 'dependent_enums.dart';

class DependentAppointmentEntity extends Equatable {
  final String id;
  final String holderUserId;
  final BeneficiaryType beneficiaryType;
  final String? beneficiaryId;
  final String? establishmentId;
  final DateTime scheduledAt;
  final DependentAppointmentStatus status;
  final String qrToken;
  final DateTime createdAt;

  const DependentAppointmentEntity({
    required this.id,
    required this.holderUserId,
    required this.beneficiaryType,
    this.beneficiaryId,
    this.establishmentId,
    required this.scheduledAt,
    required this.status,
    required this.qrToken,
    required this.createdAt,
  });

  bool get isScheduled => status == DependentAppointmentStatus.scheduled;

  @override
  List<Object?> get props => [
        id,
        holderUserId,
        beneficiaryType,
        beneficiaryId,
        establishmentId,
        scheduledAt,
        status,
        qrToken,
        createdAt,
      ];
}
