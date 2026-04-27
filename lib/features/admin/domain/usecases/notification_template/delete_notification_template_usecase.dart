import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/notification_template_repository.dart';

class DeleteNotificationTemplateUseCase {
  final NotificationTemplateRepository repository;
  DeleteNotificationTemplateUseCase(this.repository);
  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
