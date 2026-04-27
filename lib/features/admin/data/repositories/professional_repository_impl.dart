import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/professional_entity.dart';
import '../../domain/repositories/professional_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de profissionais no painel admin.
/// Faz a ponte entre Domain e Data layers.
class ProfessionalRepositoryImpl implements ProfessionalRepository {
  final AdminDataSource dataSource;

  ProfessionalRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ProfessionalEntity>>> getAll() async {
    try {
      final result = await dataSource.getProfessionals();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProfessionalEntity>> create(
      ProfessionalEntity entity) async {
    try {
      final result = await dataSource.createProfessional(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProfessionalEntity>> update(
      ProfessionalEntity entity) async {
    try {
      final result = await dataSource.updateProfessional(entity);
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
      await dataSource.deleteProfessional(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
