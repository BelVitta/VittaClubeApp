import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case para registro de novo usuário.
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
  }) {
    return repository.register(
      name: name,
      email: email,
      cpf: cpf,
      phone: phone,
      password: password,
    );
  }
}
