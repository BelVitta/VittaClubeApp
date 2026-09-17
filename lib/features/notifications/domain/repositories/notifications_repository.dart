import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../entities/notification_preferences_entity.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationEntity>>> getForCurrentUser();

  Future<Either<Failure, int>> unreadCount();

  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();

  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences();

  Future<Either<Failure, NotificationPreferencesEntity>> updatePreferences(
    NotificationPreferencesEntity preferences,
  );
}
