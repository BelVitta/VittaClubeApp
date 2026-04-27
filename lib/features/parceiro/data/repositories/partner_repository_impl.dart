import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/repositories/partner_repository.dart';
import '../datasources/parceiro_datasource.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  final ParceiroDataSource dataSource;

  PartnerRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<PartnerEntity>>> getAll() async {
    try {
      final result = await dataSource.getPartners();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PartnerEntity>> getByProfileId(String profileId) async {
    try {
      final result = await dataSource.getPartnerByProfileId(profileId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PartnerEntity>> update(PartnerEntity entity) async {
    try {
      final result = await dataSource.updatePartner(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PartnerEntity>> regenerateCode(String partnerId) async {
    try {
      final result = await dataSource.regenerateCode(partnerId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
