import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/payment_admin_entity.dart';
import '../../repositories/payment_admin_repository.dart';

class GetPaymentsUseCase {
  final PaymentAdminRepository repository;

  GetPaymentsUseCase(this.repository);

  Future<Either<Failure, List<PaymentAdminEntity>>> call() =>
      repository.getAll();
}
