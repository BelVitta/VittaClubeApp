import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dependent_appointment_entity.dart';
import '../entities/dependent_enums.dart';
import '../entities/usage_record_entity.dart';

abstract class DependentAppointmentRepository {
  Future<Either<Failure, DependentAppointmentEntity>> createAppointment({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    String? establishmentId,
    required DateTime scheduledAt,
    required String qrToken,
  });

  Future<Either<Failure, Unit>> cancelAppointment({
    required String holderUserId,
    required String appointmentId,
  });

  Future<Either<Failure, List<UsageRecordEntity>>> getUsageRecords({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required String cycleReference,
  });
}
