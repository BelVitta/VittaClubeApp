import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/partner_validation_entity.dart';
import '../../domain/repositories/partner_validation_repository.dart';
import '../datasources/parceiro_datasource.dart';

class PartnerValidationRepositoryImpl implements PartnerValidationRepository {
  final ParceiroDataSource dataSource;

  PartnerValidationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<PartnerValidationEntity>>> getByPartnerId(String partnerId) async {
    try {
      final result = await dataSource.getValidationsByPartnerId(partnerId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PartnerValidationEntity>> validateCheckin({
    required String userId,
    required String token,
    required String partnerCode,
    required String serviceId,
  }) async {
    try {
      final result = await dataSource.validateCheckin(
        userId: userId,
        token: token,
        partnerCode: partnerCode,
        serviceId: serviceId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> generateToken(String userId) async {
    try {
      final result = await dataSource.generateToken(userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
