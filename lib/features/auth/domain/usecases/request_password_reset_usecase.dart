import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepository repository;

  const RequestPasswordResetUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    final trimmed = email.trim();
    if (!Validators.isValidEmail(trimmed)) {
      return const Left(ValidationFailure('Informe um e-mail válido.'));
    }
    return repository.requestPasswordReset(email: trimmed);
  }
}
