import 'package:equatable/equatable.dart';

import '../../domain/entities/dependent_appointment_entity.dart';

enum DependentAppointmentStatusState {
  initial,
  loading,
  created,
  cancelled,
  failure,
}

class DependentAppointmentState extends Equatable {
  final DependentAppointmentStatusState status;
  final DependentAppointmentEntity? appointment;
  final String? errorMessage;

  const DependentAppointmentState({
    this.status = DependentAppointmentStatusState.initial,
    this.appointment,
    this.errorMessage,
  });

  DependentAppointmentState copyWith({
    DependentAppointmentStatusState? status,
    DependentAppointmentEntity? appointment,
    String? errorMessage,
  }) {
    return DependentAppointmentState(
      status: status ?? this.status,
      appointment: appointment ?? this.appointment,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, appointment, errorMessage];
}
