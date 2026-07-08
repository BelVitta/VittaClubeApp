import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/dependent_appointment_repository.dart';

class CancelDependentAppointmentParams {
  final String holderUserId;
  final String appointmentId;

  const CancelDependentAppointmentParams({
    required this.holderUserId,
    required this.appointmentId,
  });
}

class CancelDependentAppointmentUseCase {
  final DependentAppointmentRepository repository;

  const CancelDependentAppointmentUseCase(this.repository);

  Future<Either<Failure, Unit>> call(CancelDependentAppointmentParams params) {
    return repository.cancelAppointment(
      holderUserId: params.holderUserId,
      appointmentId: params.appointmentId,
    );
  }
}
