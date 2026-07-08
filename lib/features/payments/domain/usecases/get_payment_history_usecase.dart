import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';
import '../repositories/payments_repository.dart';

class GetPaymentHistoryUseCase {
  final PaymentsRepository repository;

  GetPaymentHistoryUseCase(this.repository);

  Future<Either<Failure, List<PaymentEntity>>> call() =>
      repository.getForCurrentUser();
}
