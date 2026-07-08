import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';

abstract class PaymentsRepository {
  /// Histórico de pagamentos do usuário logado (mais recentes primeiro).
  Future<Either<Failure, List<PaymentEntity>>> getForCurrentUser();
}
