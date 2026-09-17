import 'package:equatable/equatable.dart';

/// Preferências de categorias de notificação do membro.
class NotificationPreferencesEntity extends Equatable {
  final bool sorteios;
  final bool rankings;
  final bool pagamentos;
  final bool novidades;

  const NotificationPreferencesEntity({
    this.sorteios = true,
    this.rankings = true,
    this.pagamentos = true,
    this.novidades = true,
  });

  NotificationPreferencesEntity copyWith({
    bool? sorteios,
    bool? rankings,
    bool? pagamentos,
    bool? novidades,
  }) {
    return NotificationPreferencesEntity(
      sorteios: sorteios ?? this.sorteios,
      rankings: rankings ?? this.rankings,
      pagamentos: pagamentos ?? this.pagamentos,
      novidades: novidades ?? this.novidades,
    );
  }

  @override
  List<Object?> get props => [sorteios, rankings, pagamentos, novidades];
}
