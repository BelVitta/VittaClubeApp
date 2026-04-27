import '../../domain/entities/consultation_entity.dart';

class ConsultationModel extends ConsultationEntity {
  const ConsultationModel({
    required super.id,
    required super.title,
    super.subtitle,
    required super.scheduledDate,
    required super.status,
    super.professionalId,
    super.professionalName,
    super.specialtyName,
  });

  /// Espera o join aninhado `professionals(name, specialty_id, specialties(name))`.
  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    final prof = json['professionals'] as Map<String, dynamic>?;
    final spec = prof?['specialties'] as Map<String, dynamic>?;

    return ConsultationModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status: (json['status'] as String?) ?? 'agendada',
      professionalId: json['professional_id'] as String?,
      professionalName: prof?['name'] as String?,
      specialtyName: spec?['name'] as String?,
    );
  }
}
