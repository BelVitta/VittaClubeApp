import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de cupons de desconto.
/// Faz a ponte entre Domain e Data layers.
class CouponRepositoryImpl implements CouponRepository {
  final AdminDataSource dataSource;

  CouponRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<CouponEntity>>> getAll() async {
    try {
      final result = await dataSource.getCoupons();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> create(CouponEntity entity) async {
    try {
      final result = await dataSource.createCoupon(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> update(CouponEntity entity) async {
    try {
      final result = await dataSource.updateCoupon(entity);
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
      await dataSource.deleteCoupon(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
