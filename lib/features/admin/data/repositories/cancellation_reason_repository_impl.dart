import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cancellation_reason_entity.dart';
import '../../domain/repositories/cancellation_reason_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de motivos de cancelamento.
/// Faz a ponte entre Domain e Data layers.
class CancellationReasonRepositoryImpl implements CancellationReasonRepository {
  final AdminDataSource dataSource;

  CancellationReasonRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<CancellationReasonEntity>>> getAll() async {
    try {
      final result = await dataSource.getCancellationReasons();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CancellationReasonEntity>> create(
      CancellationReasonEntity entity) async {
    try {
      final result = await dataSource.createCancellationReason(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CancellationReasonEntity>> update(
      CancellationReasonEntity entity) async {
    try {
      final result = await dataSource.updateCancellationReason(entity);
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
      await dataSource.deleteCancellationReason(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
