import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/payment_admin_entity.dart';
import '../../repositories/payment_admin_repository.dart';

class CreatePaymentUseCase {
  final PaymentAdminRepository repository;

  CreatePaymentUseCase(this.repository);

  Future<Either<Failure, PaymentAdminEntity>> call(
          PaymentAdminEntity entity) =>
      repository.create(entity);
}
