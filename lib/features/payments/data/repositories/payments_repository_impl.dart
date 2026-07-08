import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_supabase_datasource.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsSupabaseDataSource dataSource;

  PaymentsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<PaymentEntity>>> getForCurrentUser() async {
    try {
      final result = await dataSource.getForCurrentUser();
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Erro ao buscar histórico de pagamentos: ${e.toString()}'),
      );
    }
  }
}
