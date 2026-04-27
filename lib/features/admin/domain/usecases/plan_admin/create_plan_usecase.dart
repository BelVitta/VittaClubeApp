import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/plan_admin_entity.dart';
import '../../repositories/plan_admin_repository.dart';

class CreatePlanUseCase {
  final PlanAdminRepository repository;

  CreatePlanUseCase(this.repository);

  Future<Either<Failure, PlanAdminEntity>> call(PlanAdminEntity entity) =>
      repository.create(entity);
}
