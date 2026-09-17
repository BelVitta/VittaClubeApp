import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../services/auth_session_manager.dart';

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
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String password,
    String? receptionistCode,
  }) async {
    try {
      final user = await dataSource.register(
        name: name,
        email: email,
        cpf: cpf,
        phone: phone,
        password: password,
        receptionistCode: receptionistCode,
      );
      await authSessionManager.saveSession(user);
      return Right(user);
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await dataSource.signInWithGoogle();
      await authSessionManager.saveSession(user);
      return Right(user);
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkCpfAvailable(String cpf) async {
    try {
      final available = await dataSource.checkCpfAvailable(cpf);
      return Right(available);
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset({
    required String email,
  }) async {
    try {
      await dataSource.requestPasswordReset(email: email);
      return const Right(null);
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String newPassword,
  }) async {
    try {
      await dataSource.updatePassword(newPassword: newPassword);
      return const Right(null);
    } on ServerUnavailableException {
      return const Left(ServiceUnavailableFailure());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await authSessionManager.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erro ao fazer logout: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await authSessionManager.getCachedUser();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure('Erro ao recuperar usuário: ${e.toString()}'));
    }
  }
}
