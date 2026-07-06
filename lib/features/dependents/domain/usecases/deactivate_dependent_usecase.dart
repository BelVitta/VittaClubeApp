import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/dependents_repository.dart';

class DeactivateDependentParams {
  final String holderUserId;
  final String dependentId;

  const DeactivateDependentParams({
    required this.holderUserId,
    required this.dependentId,
  });
}

class DeactivateDependentUseCase {
  final DependentsRepository repository;

  const DeactivateDependentUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DeactivateDependentParams params) {
    return repository.deactivateDependent(
      holderUserId: params.holderUserId,
      dependentId: params.dependentId,
    );
  }
}
