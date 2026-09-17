import 'package:equatable/equatable.dart';

/// Uma linha do ranking mensal de indicações - objeto de negócio puro.
/// [position] é calculado a partir da ordenação já aplicada pela consulta
/// (conversões desc, total gerado desc, nome asc).
class ReceptionistRankingEntryEntity extends Equatable {
  final int position;
  final String receptionistId;
  final String receptionistName;
  final String? receptionistCode;
  final int indicacoesCount;
  final int conversoesCount;
  final double totalGerado;

  const ReceptionistRankingEntryEntity({
    required this.position,
    required this.receptionistId,
    required this.receptionistName,
    this.receptionistCode,
    required this.indicacoesCount,
    required this.conversoesCount,
    required this.totalGerado,
  });

  @override
  List<Object?> get props => [
        position,
        receptionistId,
        receptionistName,
        receptionistCode,
        indicacoesCount,
        conversoesCount,
        totalGerado,
      ];
}
