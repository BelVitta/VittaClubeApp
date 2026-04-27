import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/plan_level.dart';

/// Representa a assinatura atual do usuário logado.
///
/// Se o usuário nunca assinou, o repositório retorna `null` no lugar desta
/// entidade — nenhum estado "none" é armazenado no banco, apenas ausência.
class SubscriptionEntity extends Equatable {
  final String id;
  final String userId;
  final String planId;
  final PlanLevel level;
  final DateTime activationDate;
  final DateTime? expirationDate;
  final bool isCurrent;
  final DateTime? cancelledAt;

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.planId,
    required this.level,
    required this.activationDate,
    this.expirationDate,
    required this.isCurrent,
    this.cancelledAt,
  });

  bool get isActive =>
      isCurrent &&
      cancelledAt == null &&
      level != PlanLevel.inadimplente &&
      level != PlanLevel.cancelado;

  @override
  List<Object?> get props =>
      [id, userId, planId, level, activationDate, expirationDate, isCurrent, cancelledAt];
}

/// Converte o enum `plan_level_status` do Supabase (snake_case em pt-br) para o
/// `PlanLevel` usado na UI.
PlanLevel planLevelFromDb(String raw) {
  switch (raw) {
    case 'bronze':
      return PlanLevel.bronze;
    case 'prata':
      return PlanLevel.silver;
    case 'ouro':
      return PlanLevel.gold;
    case 'diamante':
      return PlanLevel.diamond;
    case 'inadimplente':
      return PlanLevel.inadimplente;
    case 'cancelado':
      return PlanLevel.cancelado;
    case 'none':
    default:
      return PlanLevel.none;
  }
}

String planLevelToDb(PlanLevel level) {
  switch (level) {
    case PlanLevel.bronze:
      return 'bronze';
    case PlanLevel.silver:
      return 'prata';
    case PlanLevel.gold:
      return 'ouro';
    case PlanLevel.diamond:
      return 'diamante';
    case PlanLevel.inadimplente:
      return 'inadimplente';
    case PlanLevel.cancelado:
      return 'cancelado';
    case PlanLevel.none:
      return 'none';
  }
}
