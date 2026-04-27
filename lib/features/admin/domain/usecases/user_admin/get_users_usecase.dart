import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/user_admin_entity.dart';
import '../../repositories/user_admin_repository.dart';

class GetUsersUseCase {
  final UserAdminRepository repository;

  GetUsersUseCase(this.repository);

  Future<Either<Failure, List<UserAdminEntity>>> call() =>
      repository.getAll();
}
