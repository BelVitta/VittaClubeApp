import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cancellation_reason_entity.dart';

/// Interface do repositório de motivos de cancelamento.
/// Define o contrato que a camada Data deve implementar.
abstract class CancellationReasonRepository {
  /// Obtém todos os motivos de cancelamento
  Future<Either<Failure, List<CancellationReasonEntity>>> getAll();

  /// Cria um novo motivo de cancelamento
  Future<Either<Failure, CancellationReasonEntity>> create(
      CancellationReasonEntity entity);

  /// Atualiza um motivo de cancelamento existente
  Future<Either<Failure, CancellationReasonEntity>> update(
      CancellationReasonEntity entity);

  /// Remove um motivo de cancelamento pelo ID
  Future<Either<Failure, void>> delete(String id);
}
