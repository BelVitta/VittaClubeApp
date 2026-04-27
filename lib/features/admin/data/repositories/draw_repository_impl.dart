import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/draw_entity.dart';
import '../../domain/repositories/draw_repository.dart';
import '../datasources/admin_datasource.dart';

class DrawRepositoryImpl implements DrawRepository {
  final AdminDataSource dataSource;

  DrawRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<DrawEntity>>> getAll() async {
    try {
      final result = await dataSource.getDraws();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DrawEntity>> create(DrawEntity entity) async {
    try {
      final result = await dataSource.createDraw(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DrawEntity>> update(DrawEntity entity) async {
    try {
      final result = await dataSource.updateDraw(entity);
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
      await dataSource.deleteDraw(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DrawEntity>> executeDraw(String drawId) async {
    try {
      final result = await dataSource.executeDraw(drawId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
