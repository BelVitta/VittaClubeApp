import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/payment_admin_entity.dart';
import '../../repositories/payment_admin_repository.dart';

class UpdatePaymentUseCase {
  final PaymentAdminRepository repository;

  UpdatePaymentUseCase(this.repository);

  Future<Either<Failure, PaymentAdminEntity>> call(
          PaymentAdminEntity entity) =>
      repository.update(entity);
}
