import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/plan_admin_repository.dart';

class DeletePlanUseCase {
  final PlanAdminRepository repository;

  DeletePlanUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
