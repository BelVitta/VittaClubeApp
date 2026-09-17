import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository repository;

  const UpdatePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!Validators.isValidPassword(newPassword)) {
      return const Left(
        ValidationFailure('A senha deve ter pelo menos 6 caracteres.'),
      );
    }
    if (!Validators.passwordsMatch(newPassword, confirmPassword)) {
      return const Left(ValidationFailure('As senhas não coincidem.'));
    }
    return repository.updatePassword(newPassword: newPassword);
  }
}
