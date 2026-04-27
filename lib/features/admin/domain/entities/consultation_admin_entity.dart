import 'package:equatable/equatable.dart';

/// Entidade de consulta no painel admin - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class ConsultationAdminEntity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final String professionalId;
  final String professionalName;
  final String userId;
  final String userName;

  const ConsultationAdminEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.professionalId,
    required this.professionalName,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        date,
        professionalId,
        professionalName,
        userId,
        userName,
      ];
}
