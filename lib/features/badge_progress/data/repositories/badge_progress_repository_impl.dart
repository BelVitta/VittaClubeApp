import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/badge_progress_entity.dart';
import '../../domain/repositories/badge_progress_repository.dart';
import '../datasources/badge_progress_supabase_datasource.dart';
import '../models/badge_progress_model.dart';

/// Implementacao do repositorio de progresso de badges.
class BadgeProgressRepositoryImpl implements BadgeProgressRepository {
  final BadgeProgressSupabaseDataSource dataSource;

  BadgeProgressRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, BadgeProgressEntity>> getProgress(
      String userId) async {
    try {
      final result = await dataSource.getProgress(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar progresso: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BadgeProgressEntity>> checkAndUpgrade(
      String userId) async {
    try {
      final result = await dataSource.checkAndUpgrade(userId);
      return Right(result);
    } catch (e) {
      return Left(
          ServerFailure('Erro ao verificar upgrade: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BadgeProgressEntity>> updateProgress(
      BadgeProgressEntity progress) async {
    try {
      final model = BadgeProgressModel.fromEntity(progress);
      final result = await dataSource.updateProgress(model);
      return Right(result);
    } catch (e) {
      return Left(
          ServerFailure('Erro ao atualizar progresso: ${e.toString()}'));
    }
  }
}
