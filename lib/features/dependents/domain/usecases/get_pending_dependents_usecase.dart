import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_dependent_entity.dart';
import '../repositories/dependents_repository.dart';

/// Admin-only: lista todos os dependentes aguardando aprovação presencial.
class GetPendingDependentsUseCase {
  final DependentsRepository repository;

  const GetPendingDependentsUseCase(this.repository);

  Future<Either<Failure, List<PendingDependentEntity>>> call() {
    return repository.getPendingDependents();
  }
}
