import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadCountUseCase {
  final NotificationsRepository repository;

  GetUnreadCountUseCase(this.repository);

  Future<Either<Failure, int>> call() => repository.unreadCount();
}
