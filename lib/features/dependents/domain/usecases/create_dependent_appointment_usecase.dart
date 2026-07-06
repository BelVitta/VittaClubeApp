import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_appointment_entity.dart';
import '../entities/dependent_enums.dart';
import '../repositories/dependent_appointment_repository.dart';
import '../services/qr_token_service.dart';

class CreateDependentAppointmentParams {
  final String holderUserId;
  final BeneficiaryType beneficiaryType;
  final String? beneficiaryId;
  final String? establishmentId;
  final DateTime scheduledAt;

  const CreateDependentAppointmentParams({
    required this.holderUserId,
    required this.beneficiaryType,
    this.beneficiaryId,
    this.establishmentId,
    required this.scheduledAt,
  });
}

class CreateDependentAppointmentUseCase {
  final DependentAppointmentRepository repository;
  final QrTokenService qrTokenService;

  const CreateDependentAppointmentUseCase({
    required this.repository,
    required this.qrTokenService,
  });

  Future<Either<Failure, DependentAppointmentEntity>> call(
    CreateDependentAppointmentParams params,
  ) async {
    if (params.beneficiaryType == BeneficiaryType.dependent &&
        (params.beneficiaryId == null || params.beneficiaryId!.isEmpty)) {
      return const Left(
        ValidationFailure('Selecione um dependente para o agendamento.'),
      );
    }

    final token = await qrTokenService.generateAppointmentToken(
      holderUserId: params.holderUserId,
      beneficiaryType: params.beneficiaryType,
      beneficiaryId: params.beneficiaryId,
      scheduledAt: params.scheduledAt,
    );

    return repository.createAppointment(
      holderUserId: params.holderUserId,
      beneficiaryType: params.beneficiaryType,
      beneficiaryId: params.beneficiaryId,
      establishmentId: params.establishmentId,
      scheduledAt: params.scheduledAt,
      qrToken: token,
    );
  }
}
