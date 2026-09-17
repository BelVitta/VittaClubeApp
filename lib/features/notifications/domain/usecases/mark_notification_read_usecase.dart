import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository repository;

  MarkNotificationReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.markRead(id);
}
