import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/partner_application_entity.dart';
import '../../domain/repositories/partner_application_repository.dart';
import '../datasources/parceiro_datasource.dart';

class PartnerApplicationRepositoryImpl implements PartnerApplicationRepository {
  final ParceiroDataSource dataSource;

  PartnerApplicationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> submit({
    required String name,
    required String category,
    String? address,
    String? phone,
    required String email,
    String? userId,
  }) async {
    try {
      await dataSource.submitPartnerApplication(
        name: name,
        category: category,
        address: address,
        phone: phone,
        email: email,
        userId: userId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PartnerApplicationEntity>>> getAll() async {
    try {
      final result = await dataSource.getPartnerApplications();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> approve(
    String id, {
    required String reviewerId,
  }) async {
    try {
      await dataSource.approvePartnerApplication(id, reviewerId: reviewerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> reject(
    String id, {
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await dataSource.rejectPartnerApplication(
        id,
        reviewerId: reviewerId,
        reason: reason,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
