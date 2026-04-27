import 'package:equatable/equatable.dart';

/// Entidade de sorteio - objeto de negócio puro.
class DrawEntity extends Equatable {
  final String id;
  final String name;
  final String prizeName;
  final String? prizeDescription;
  final String? prizeImageUrl;
  final DateTime drawDate;
  final DateTime? registrationStartDate;
  final DateTime? registrationEndDate;
  final String status; // 'agendado', 'inscricoes_abertas', 'inscricoes_encerradas', 'realizado', 'cancelado'
  final int participantCount;
  final String? winnerId;
  final String? winnerName;
  final List<String> eligiblePlanLevels;
  final String? rules;

  // Campos de auditoria do sorteio (transparência)
  final String? drawSeedHash; // Hash SHA-256 da seed usada
  final String? participantListHash; // Hash da lista de participantes no momento do sorteio
  final DateTime? executedAt; // Quando o sorteio foi realizado
  final int? winnerIndex; // Índice sorteado na lista

  const DrawEntity({
    required this.id,
    required this.name,
    required this.prizeName,
    this.prizeDescription,
    this.prizeImageUrl,
    required this.drawDate,
    this.registrationStartDate,
    this.registrationEndDate,
    required this.status,
    required this.participantCount,
    this.winnerId,
    this.winnerName,
    this.eligiblePlanLevels = const [],
    this.rules,
    this.drawSeedHash,
    this.participantListHash,
    this.executedAt,
    this.winnerIndex,
  });

  /// Verifica se um nivel de plano é elegível para este sorteio.
  /// Lista vazia significa que todos os níveis são elegíveis.
  bool isPlanLevelEligible(String planLevel) {
    if (eligiblePlanLevels.isEmpty) return true;
    return eligiblePlanLevels.contains(planLevel.toLowerCase());
  }

  bool get canExecuteDraw =>
      status == 'inscricoes_encerradas' && winnerId == null;

  bool get isCompleted => status == 'realizado';

  @override
  List<Object?> get props => [
        id,
        name,
        prizeName,
        prizeDescription,
        prizeImageUrl,
        drawDate,
        registrationStartDate,
        registrationEndDate,
        status,
        participantCount,
        winnerId,
        winnerName,
        eligiblePlanLevels,
        rules,
        drawSeedHash,
        participantListHash,
        executedAt,
        winnerIndex,
      ];
}
