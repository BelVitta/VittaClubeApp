import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/consultation_admin_entity.dart';
import '../../domain/repositories/consultation_admin_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de consultas no painel admin.
/// Faz a ponte entre Domain e Data layers.
class ConsultationAdminRepositoryImpl implements ConsultationAdminRepository {
  final AdminDataSource dataSource;

  ConsultationAdminRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ConsultationAdminEntity>>> getAll() async {
    try {
      final result = await dataSource.getConsultations();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ConsultationAdminEntity>> create(
      ConsultationAdminEntity entity) async {
    try {
      final result = await dataSource.createConsultation(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ConsultationAdminEntity>> update(
      ConsultationAdminEntity entity) async {
    try {
      final result = await dataSource.updateConsultation(entity);
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
      await dataSource.deleteConsultation(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
