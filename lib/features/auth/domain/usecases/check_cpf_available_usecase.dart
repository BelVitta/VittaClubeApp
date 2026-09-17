import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Checa se um CPF já está em uso por outra conta, antes do cadastro.
class CheckCpfAvailableUseCase {
  final AuthRepository repository;

  CheckCpfAvailableUseCase(this.repository);

  Future<Either<Failure, bool>> call(String cpf) =>
      repository.checkCpfAvailable(cpf);
}
