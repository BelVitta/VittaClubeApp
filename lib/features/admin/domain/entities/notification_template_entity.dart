import 'package:equatable/equatable.dart';

/// Entidade de template de notificação - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class NotificationTemplateEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final String triggerEvent;
  final bool isActive;

  const NotificationTemplateEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.triggerEvent,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, title, body, type, triggerEvent, isActive];
}
