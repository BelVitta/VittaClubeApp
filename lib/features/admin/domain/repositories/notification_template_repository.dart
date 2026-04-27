import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_template_entity.dart';

/// Interface do repositório de templates de notificação.
/// Define o contrato que a camada Data deve implementar.
abstract class NotificationTemplateRepository {
  /// Obtém todos os templates de notificação
  Future<Either<Failure, List<NotificationTemplateEntity>>> getAll();

  /// Cria um novo template de notificação
  Future<Either<Failure, NotificationTemplateEntity>> create(
      NotificationTemplateEntity entity);

  /// Atualiza um template de notificação existente
  Future<Either<Failure, NotificationTemplateEntity>> update(
      NotificationTemplateEntity entity);

  /// Remove um template de notificação pelo ID
  Future<Either<Failure, void>> delete(String id);
}
