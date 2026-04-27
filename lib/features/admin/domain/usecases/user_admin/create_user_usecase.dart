import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/user_admin_entity.dart';
import '../../repositories/user_admin_repository.dart';

class CreateUserUseCase {
  final UserAdminRepository repository;

  CreateUserUseCase(this.repository);

  Future<Either<Failure, UserAdminEntity>> call(UserAdminEntity entity) =>
      repository.create(entity);
}
