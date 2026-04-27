import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/referral_entity.dart';
import '../../domain/repositories/referral_repository.dart';
import '../datasources/referral_supabase_datasource.dart';

/// Implementacao do repositorio de indicacoes.
class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralSupabaseDataSource dataSource;

  ReferralRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ReferralEntity>>> getReferralsByUser(
      String userId) async {
    try {
      final result = await dataSource.getReferralsByUser(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar indicacoes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> createReferral(
      String userId) async {
    try {
      final result = await dataSource.createReferral(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao criar indicacao: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> validateReferralCode(
      String code, String referredUserId) async {
    try {
      final result =
          await dataSource.validateReferralCode(code, referredUserId);
      return Right(result);
    } catch (e) {
      return Left(ValidationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> claimReward(
      String referralId) async {
    try {
      final result = await dataSource.claimReward(referralId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao resgatar recompensa: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getReferralCountThisMonth(
      String userId) async {
    try {
      final result = await dataSource.getReferralCountThisMonth(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao contar indicacoes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReferralEntity>> getReferralByCode(
      String code) async {
    try {
      final result = await dataSource.getReferralByCode(code);
      return Right(result);
    } catch (e) {
      return Left(ValidationFailure(e.toString()));
    }
  }
}
