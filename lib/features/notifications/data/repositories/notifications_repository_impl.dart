import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_supabase_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsSupabaseDataSource dataSource;

  NotificationsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<NotificationEntity>>> getForCurrentUser() async {
    try {
      return Right(await dataSource.getForCurrentUser());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar notificações: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> unreadCount() async {
    try {
      return Right(await dataSource.unreadCount());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao contar notificações: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    try {
      await dataSource.markRead(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao marcar notificação: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await dataSource.markAllRead();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao marcar notificações: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>>
      getPreferences() async {
    try {
      return Right(await dataSource.getPreferences());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar preferências: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> updatePreferences(
    NotificationPreferencesEntity preferences,
  ) async {
    try {
      return Right(await dataSource.updatePreferences(preferences));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao salvar preferências: $e'));
    }
  }
}
