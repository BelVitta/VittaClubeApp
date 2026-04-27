import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/user_admin_entity.dart';
import '../../repositories/user_admin_repository.dart';

class UpdateUserUseCase {
  final UserAdminRepository repository;

  UpdateUserUseCase(this.repository);

  Future<Either<Failure, UserAdminEntity>> call(UserAdminEntity entity) =>
      repository.update(entity);
}
