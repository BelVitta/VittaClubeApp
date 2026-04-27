import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/notification_template_entity.dart';
import '../../repositories/notification_template_repository.dart';

class CreateNotificationTemplateUseCase {
  final NotificationTemplateRepository repository;
  CreateNotificationTemplateUseCase(this.repository);
  Future<Either<Failure, NotificationTemplateEntity>> call(
          NotificationTemplateEntity entity) =>
      repository.create(entity);
}
