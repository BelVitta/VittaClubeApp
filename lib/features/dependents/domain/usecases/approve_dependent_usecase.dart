import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/dependents_repository.dart';

/// Admin-only: aprova presencialmente um dependente `pending`, tornando-o
/// `active`. O RLS/trigger no banco rejeita a chamada se quem executar não
/// tiver `role` admin/financeiro.
class ApproveDependentUseCase {
  final DependentsRepository repository;

  const ApproveDependentUseCase(this.repository);

  Future<Either<Failure, Unit>> call({required String dependentId}) {
    return repository.approveDependent(dependentId: dependentId);
  }
}
