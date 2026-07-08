import 'package:equatable/equatable.dart';

import '../../domain/entities/dependent_enums.dart';

abstract class DependentAppointmentEvent extends Equatable {
  const DependentAppointmentEvent();

  @override
  List<Object?> get props => [];
}

class CreateDependentAppointmentRequested extends DependentAppointmentEvent {
  final String holderUserId;
  final BeneficiaryType beneficiaryType;
  final String? beneficiaryId;
  final String? establishmentId;
  final DateTime scheduledAt;

  const CreateDependentAppointmentRequested({
    required this.holderUserId,
    required this.beneficiaryType,
    this.beneficiaryId,
    this.establishmentId,
    required this.scheduledAt,
  });

  @override
  List<Object?> get props => [
        holderUserId,
        beneficiaryType,
        beneficiaryId,
        establishmentId,
        scheduledAt,
      ];
}

class CancelDependentAppointmentRequested extends DependentAppointmentEvent {
  final String holderUserId;
  final String appointmentId;

  const CancelDependentAppointmentRequested({
    required this.holderUserId,
    required this.appointmentId,
  });

  @override
  List<Object?> get props => [holderUserId, appointmentId];
}
