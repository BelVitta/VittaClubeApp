import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/plan_admin_entity.dart';
import '../../repositories/plan_admin_repository.dart';

class GetPlansUseCase {
  final PlanAdminRepository repository;

  GetPlansUseCase(this.repository);

  Future<Either<Failure, List<PlanAdminEntity>>> call() =>
      repository.getAll();
}
