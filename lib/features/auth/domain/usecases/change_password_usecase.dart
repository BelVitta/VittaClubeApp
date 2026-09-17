import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  const ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return const Left(ValidationFailure('Informe a senha atual.'));
    }
    if (!Validators.isValidPassword(newPassword)) {
      return const Left(
        ValidationFailure('A nova senha deve ter pelo menos 6 caracteres.'),
      );
    }
    if (!Validators.passwordsMatch(newPassword, confirmPassword)) {
      return const Left(ValidationFailure('As senhas não coincidem.'));
    }
    if (currentPassword == newPassword) {
      return const Left(
        ValidationFailure('A nova senha deve ser diferente da atual.'),
      );
    }

    return repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
