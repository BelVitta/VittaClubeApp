import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/user_admin_repository.dart';

class DeleteUserUseCase {
  final UserAdminRepository repository;

  DeleteUserUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
