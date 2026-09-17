import 'package:equatable/equatable.dart';

/// Destino ao tocar na notificação (payload `data.action`).
enum NotificationAction {
  none,
  professional,
  professionals,
  plans,
  partners,
}

NotificationAction notificationActionFromString(String? raw) {
  switch (raw) {
    case 'professional':
      return NotificationAction.professional;
    case 'professionals':
      return NotificationAction.professionals;
    case 'plans':
      return NotificationAction.plans;
    case 'partners':
      return NotificationAction.partners;
    default:
      return NotificationAction.none;
  }
}

/// Aviso in-app do membro (tabela `notifications`).
class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final NotificationAction action;
  final String? professionalId;
  final String? professionalName;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.action = NotificationAction.none,
    this.professionalId,
    this.professionalName,
  });

  NotificationEntity copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      action: action,
      professionalId: professionalId,
      professionalName: professionalName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        isRead,
        readAt,
        createdAt,
        action,
        professionalId,
        professionalName,
      ];
}
