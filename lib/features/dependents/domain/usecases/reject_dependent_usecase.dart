import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/dependents_repository.dart';

/// Admin-only: rejeita um dependente `pending` (vira `inactive`, mantido
/// para auditoria em vez de apagado).
class RejectDependentUseCase {
  final DependentsRepository repository;

  const RejectDependentUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String dependentId,
    required String reason,
  }) {
    return repository.rejectDependent(dependentId: dependentId, reason: reason);
  }
}
