import 'package:equatable/equatable.dart';

/// Classe base para falhas no app.
/// Usar com `Either<Failure, Success>` do dartz.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Falha de servidor (API retornou erro)
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erro no servidor. Tente novamente.']);
}

/// Falha de cache local
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erro ao acessar dados locais.']);
}

/// Falha de conexão de rede
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

/// Falha de validação de dados
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Falha de autenticação
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erro de autenticação.']);
}
