import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/notification_template_entity.dart';
import '../../repositories/notification_template_repository.dart';

class GetNotificationTemplatesUseCase {
  final NotificationTemplateRepository repository;
  GetNotificationTemplatesUseCase(this.repository);
  Future<Either<Failure, List<NotificationTemplateEntity>>> call() =>
      repository.getAll();
}
