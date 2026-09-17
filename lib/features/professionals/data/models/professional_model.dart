import '../../domain/entities/professional_entity.dart';

class ProfessionalModel extends ProfessionalEntity {
  const ProfessionalModel({
    required super.id,
    required super.name,
    required super.specialtyName,
    required super.availableDays,
    super.availabilityNote,
    super.avatarUrl,
    required super.avatarBgColor,
  });

  /// Espera o join `specialties(name)`.
  factory ProfessionalModel.fromJson(Map<String, dynamic> json) {
    final specialty = json['specialties'] as Map<String, dynamic>?;
    final days = (json['available_days'] as List<dynamic>?)
            ?.map((d) => d.toString())
            .join(', ') ??
        '';

    return ProfessionalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      specialtyName: specialty?['name'] as String? ?? '',
      availableDays: days,
      availabilityNote: json['availability_note'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      avatarBgColor: json['avatar_bg_color'] as int? ?? 0xFFFFCD66,
    );
  }
}
