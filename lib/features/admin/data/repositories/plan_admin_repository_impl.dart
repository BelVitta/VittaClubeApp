import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/plan_admin_entity.dart';
import '../../domain/repositories/plan_admin_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de planos no painel admin.
/// Faz a ponte entre Domain e Data layers.
class PlanAdminRepositoryImpl implements PlanAdminRepository {
  final AdminDataSource dataSource;

  PlanAdminRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<PlanAdminEntity>>> getAll() async {
    try {
      final result = await dataSource.getPlans();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PlanAdminEntity>> create(
      PlanAdminEntity entity) async {
    try {
      final result = await dataSource.createPlan(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PlanAdminEntity>> update(
      PlanAdminEntity entity) async {
    try {
      final result = await dataSource.updatePlan(entity);
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
      await dataSource.deletePlan(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
