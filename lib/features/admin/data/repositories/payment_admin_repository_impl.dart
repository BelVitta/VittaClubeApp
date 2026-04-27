import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_admin_entity.dart';
import '../../domain/repositories/payment_admin_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de pagamentos no painel admin.
/// Faz a ponte entre Domain e Data layers.
class PaymentAdminRepositoryImpl implements PaymentAdminRepository {
  final AdminDataSource dataSource;

  PaymentAdminRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<PaymentAdminEntity>>> getAll() async {
    try {
      final result = await dataSource.getPayments();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentAdminEntity>> create(
      PaymentAdminEntity entity) async {
    try {
      final result = await dataSource.createPayment(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentAdminEntity>> update(
      PaymentAdminEntity entity) async {
    try {
      final result = await dataSource.updatePayment(entity);
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
      await dataSource.deletePayment(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
