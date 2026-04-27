import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/payment_admin_repository.dart';

class DeletePaymentUseCase {
  final PaymentAdminRepository repository;

  DeletePaymentUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
