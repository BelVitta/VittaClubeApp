import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/repositories/badge_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de badges/emblemas.
/// Faz a ponte entre Domain e Data layers.
class BadgeRepositoryImpl implements BadgeRepository {
  final AdminDataSource dataSource;

  BadgeRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<BadgeEntity>>> getAll() async {
    try {
      final result = await dataSource.getBadges();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BadgeEntity>> create(BadgeEntity entity) async {
    try {
      final result = await dataSource.createBadge(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BadgeEntity>> update(BadgeEntity entity) async {
    try {
      final result = await dataSource.updateBadge(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await dataSource.deleteBadge(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
