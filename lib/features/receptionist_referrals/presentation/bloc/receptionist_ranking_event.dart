import 'package:equatable/equatable.dart';

abstract class ReceptionistRankingEvent extends Equatable {
  const ReceptionistRankingEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega o ranking do mês informado (formato 'YYYY-MM'). Sem argumento,
/// usa o mês corrente.
class LoadReceptionistRanking extends ReceptionistRankingEvent {
  final String? monthReference;

  const LoadReceptionistRanking({this.monthReference});

  @override
  List<Object?> get props => [monthReference];
}
