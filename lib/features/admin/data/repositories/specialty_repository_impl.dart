import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/specialty_entity.dart';
import '../../domain/repositories/specialty_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de especialidades.
/// Faz a ponte entre Domain e Data layers.
class SpecialtyRepositoryImpl implements SpecialtyRepository {
  final AdminDataSource dataSource;

  SpecialtyRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<SpecialtyEntity>>> getAll() async {
    try {
      final result = await dataSource.getSpecialties();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SpecialtyEntity>> create(
      SpecialtyEntity entity) async {
    try {
      final result = await dataSource.createSpecialty(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SpecialtyEntity>> update(
      SpecialtyEntity entity) async {
    try {
      final result = await dataSource.updateSpecialty(entity);
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
      await dataSource.deleteSpecialty(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
