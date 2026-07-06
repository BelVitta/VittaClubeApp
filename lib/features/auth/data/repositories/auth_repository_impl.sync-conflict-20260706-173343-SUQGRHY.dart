import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../services/auth_session_manager.dart';

/// Implementação do repositório de autenticação.
/// Faz a ponte entre Domain e Data layers.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;
  final AuthSessionManager authSessionManager;

  AuthRepositoryImpl({
    required this.dataSource,
    required this.authSessionManager,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await dataSource.login(email: email, password: password);
      await authSessionManager.saveSession(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error(
        'Erro inesperado no login.',
        name: 'AuthRepositoryImpl',
        error: e,
      );
      return Left(ServerFailure(
        'Não foi possível fazer login. Tente novamente em instantes.',
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
  }) async {
    try {
      final user = await dataSource.register(
        name: name,
        email: email,
        cpf: cpf,
        phone: phone,
        password: password,
      );
      await authSessionManager.saveSession(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error(
        'Erro inesperado no cadastro.',
        name: 'AuthRepositoryImpl',
        error: e,
      );
      return Left(ServerFailure(
        'Não foi possível criar sua conta. Tente novamente em instantes.',
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await dataSource.signInWithGoogle();
      await authSessionManager.saveSession(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error(
        'Erro inesperado no login com Google.',
        name: 'AuthRepositoryImpl',
        error: e,
      );
      return Left(ServerFailure(
        'Não foi possível entrar com Google. Tente novamente em instantes.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await authSessionManager.clearSession();
      return const Right(null);
    } catch (e) {
      AppLogger.error(
        'Erro ao fazer logout.',
        name: 'AuthRepositoryImpl',
        error: e,
      );
      return Left(CacheFailure('Não foi possível sair da conta.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await authSessionManager.getCachedUser();
      return Right(user);
    } catch (e) {
      AppLogger.error(
        'Erro ao recuperar usuário atual.',
        name: 'AuthRepositoryImpl',
        error: e,
      );
      return Left(CacheFailure(
        'Não foi possível recuperar a sessão. Faça login novamente.',
      ));
    }
  }
}
