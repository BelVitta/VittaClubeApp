import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/partner_service_entity.dart';
import '../../domain/repositories/partner_service_repository.dart';
import '../datasources/parceiro_datasource.dart';

class PartnerServiceRepositoryImpl implements PartnerServiceRepository {
  final ParceiroDataSource dataSource;

  PartnerServiceRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<PartnerServiceEntity>>> getByPartnerId(String partnerId) async {
    try {
      final result = await dataSource.getServicesByPartnerId(partnerId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PartnerServiceEntity>>> getAllActive() async {
    try {
      final result = await dataSource.getAllActiveServices();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PartnerServiceEntity>> create(PartnerServiceEntity entity) async {
    try {
      final result = await dataSource.createService(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PartnerServiceEntity>> update(PartnerServiceEntity entity) async {
    try {
      final result = await dataSource.updateService(entity);
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
      await dataSource.deleteService(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
