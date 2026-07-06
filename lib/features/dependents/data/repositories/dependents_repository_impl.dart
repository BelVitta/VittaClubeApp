import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/dependent_appointment_entity.dart';
import '../../domain/entities/dependent_entity.dart';
import '../../domain/entities/dependent_enums.dart';
import '../../domain/entities/usage_record_entity.dart';
import '../../domain/repositories/dependent_appointment_repository.dart';
import '../../domain/repositories/dependents_repository.dart';
import '../../domain/repositories/qr_validation_repository.dart';
import '../datasources/dependents_datasource.dart';
import '../models/dependent_models.dart';
import '../models/qr_validation_result_model.dart';

class DependentsRepositoryImpl implements DependentsRepository {
  final DependentsDataSource dataSource;

  DependentsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, DependentEntity>> createDependent({
    required String holderUserId,
    required String name,
    required String cpf,
    required DateTime birthDate,
    required String relationship,
  }) async {
    try {
      final row = await dataSource.createDependent(
        holderUserId: holderUserId,
        name: name,
        cpf: cpf,
        birthDate: birthDate,
        relationship: relationship,
      );
      return Right(DependentModel.fromJson(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DependentEntity>>> getDependents({
    required String holderUserId,
    DependentStatus? status,
  }) async {
    try {
      final rows = await dataSource.getDependents(
        holderUserId: holderUserId,
        status: status?.dbValue,
      );
      return Right(rows.map(DependentModel.fromJson).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deactivateDependent({
    required String holderUserId,
    required String dependentId,
  }) async {
    try {
      await dataSource.deactivateDependent(
        holderUserId: holderUserId,
        dependentId: dependentId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> countActiveDependents({
    required String holderUserId,
  }) async {
    try {
      return Right(
        await dataSource.countActiveDependents(holderUserId: holderUserId),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> activeCpfExists(String cpf) async {
    try {
      return Right(await dataSource.activeCpfExists(cpf));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class DependentAppointmentRepositoryImpl
    implements DependentAppointmentRepository {
  final DependentAppointmentDataSource dataSource;

  DependentAppointmentRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, DependentAppointmentEntity>> createAppointment({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    String? establishmentId,
    required DateTime scheduledAt,
    required String qrToken,
  }) async {
    try {
      final row = await dataSource.createAppointment(
        holderUserId: holderUserId,
        beneficiaryType: beneficiaryType,
        beneficiaryId: beneficiaryId,
        establishmentId: establishmentId,
        scheduledAt: scheduledAt,
        qrToken: qrToken,
      );
      return Right(DependentAppointmentModel.fromJson(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelAppointment({
    required String holderUserId,
    required String appointmentId,
  }) async {
    try {
      await dataSource.cancelAppointment(
        holderUserId: holderUserId,
        appointmentId: appointmentId,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UsageRecordEntity>>> getUsageRecords({
    required String holderUserId,
    required BeneficiaryType beneficiaryType,
    String? beneficiaryId,
    required String cycleReference,
  }) async {
    try {
      final rows = await dataSource.getUsageRecords(
        holderUserId: holderUserId,
        beneficiaryType: beneficiaryType,
        beneficiaryId: beneficiaryId,
        cycleReference: cycleReference,
      );
      return Right(rows.map(UsageRecordModel.fromJson).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class QrValidationRepositoryImpl implements QrValidationRepository {
  final QrValidationDataSource dataSource;

  QrValidationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, QrValidationResult>> validateQr({
    required String qrToken,
    required String actorUserId,
    String? establishmentId,
  }) async {
    try {
      final row = await dataSource.validateQr(
        qrToken: qrToken,
        actorUserId: actorUserId,
        establishmentId: establishmentId,
      );
      return Right(QrValidationResultModel.fromJson(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
