import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_template_entity.dart';
import '../../domain/repositories/notification_template_repository.dart';
import '../datasources/admin_datasource.dart';

/// Implementação do repositório de templates de notificação.
/// Faz a ponte entre Domain e Data layers.
class NotificationTemplateRepositoryImpl
    implements NotificationTemplateRepository {
  final AdminDataSource dataSource;

  NotificationTemplateRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<NotificationTemplateEntity>>> getAll() async {
    try {
      final result = await dataSource.getNotifications();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NotificationTemplateEntity>> create(
      NotificationTemplateEntity entity) async {
    try {
      final result = await dataSource.createNotification(entity);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, NotificationTemplateEntity>> update(
      NotificationTemplateEntity entity) async {
    try {
      final result = await dataSource.updateNotification(entity);
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
      await dataSource.deleteNotification(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
