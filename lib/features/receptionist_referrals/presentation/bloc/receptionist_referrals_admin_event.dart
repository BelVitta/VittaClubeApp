import 'package:equatable/equatable.dart';

import '../../domain/entities/receptionist_referral_entity.dart';

abstract class ReceptionistReferralsAdminEvent extends Equatable {
  const ReceptionistReferralsAdminEvent();

  @override
  List<Object?> get props => [];
}

/// Busca no servidor por mês/recepcionista/status (os 3 filtros que reduzem
/// o volume trazido do banco). Chamar de novo refaz o fetch.
class LoadReferrals extends ReceptionistReferralsAdminEvent {
  final String? monthReference;
  final String? receptionistId;
  final ReceptionistReferralStatus? status;

  const LoadReferrals({
    this.monthReference,
    this.receptionistId,
    this.status,
  });

  @override
  List<Object?> get props => [monthReference, receptionistId, status];
}

/// Busca por nome/e-mail do indicado - aplicada em memória sobre o que já
/// foi carregado, igual ao restante do painel admin.
class SearchReferrals extends ReceptionistReferralsAdminEvent {
  final String query;

  const SearchReferrals(this.query);

  @override
  List<Object?> get props => [query];
}

class CorrectReferralAttributionRequested
    extends ReceptionistReferralsAdminEvent {
  final String referralId;
  final String newReceptionistId;
  final String reason;

  const CorrectReferralAttributionRequested({
    required this.referralId,
    required this.newReceptionistId,
    required this.reason,
  });

  @override
  List<Object?> get props => [referralId, newReceptionistId, reason];
}
