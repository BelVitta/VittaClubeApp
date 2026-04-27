import 'package:equatable/equatable.dart';

/// Consulta agendada ou realizada pelo usuário atual.
class ConsultationEntity extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime scheduledDate;
  final String status;
  final String? professionalId;
  final String? professionalName;
  final String? specialtyName;

  const ConsultationEntity({
    required this.id,
    required this.title,
    this.subtitle,
    required this.scheduledDate,
    required this.status,
    this.professionalId,
    this.professionalName,
    this.specialtyName,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        scheduledDate,
        status,
        professionalId,
        professionalName,
        specialtyName,
      ];
}
