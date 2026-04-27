import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_admin_entity.dart';

/// Interface do repositório de pagamentos no painel admin.
/// Define o contrato que a camada Data deve implementar.
abstract class PaymentAdminRepository {
  /// Obtém todos os pagamentos
  Future<Either<Failure, List<PaymentAdminEntity>>> getAll();

  /// Cria um novo pagamento
  Future<Either<Failure, PaymentAdminEntity>> create(PaymentAdminEntity entity);

  /// Atualiza um pagamento existente
  Future<Either<Failure, PaymentAdminEntity>> update(PaymentAdminEntity entity);

  /// Remove um pagamento pelo ID
  Future<Either<Failure, void>> delete(String id);
}
