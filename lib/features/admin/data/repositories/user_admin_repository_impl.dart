import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_admin_entity.dart';
import '../../domain/repositories/user_admin_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de usuários no painel admin.
/// Faz a ponte entre Domain e Data layers.
class UserAdminRepositoryImpl implements UserAdminRepository {
  final AdminDataSource dataSource;

  UserAdminRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<UserAdminEntity>>> getAll() async {
    try {
      final result = await dataSource.getUsers();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserAdminEntity>> create(
      UserAdminEntity entity) async {
    try {
      final result = await dataSource.createUser(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserAdminEntity>> update(
      UserAdminEntity entity) async {
    try {
      final result = await dataSource.updateUser(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await dataSource.deleteUser(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
