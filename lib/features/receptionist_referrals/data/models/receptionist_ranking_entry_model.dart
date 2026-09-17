import '../../domain/entities/receptionist_ranking_entry_entity.dart';

/// Model de linha do ranking mensal - DTO a partir do retorno da RPC
/// `get_receptionist_monthly_ranking`.
class ReceptionistRankingEntryModel extends ReceptionistRankingEntryEntity {
  const ReceptionistRankingEntryModel({
    required super.position,
    required super.receptionistId,
    required super.receptionistName,
    super.receptionistCode,
    required super.indicacoesCount,
    required super.conversoesCount,
    required super.totalGerado,
  });

  factory ReceptionistRankingEntryModel.fromRow(
    Map<String, dynamic> row, {
    required int position,
  }) {
    return ReceptionistRankingEntryModel(
      position: position,
      receptionistId: row['receptionist_id'] as String,
      receptionistName: row['receptionist_name'] as String? ?? '',
      receptionistCode: row['receptionist_code'] as String?,
      indicacoesCount: (row['indicacoes_count'] as num?)?.toInt() ?? 0,
      conversoesCount: (row['conversoes_count'] as num?)?.toInt() ?? 0,
      totalGerado: (row['total_gerado'] as num?)?.toDouble() ?? 0,
    );
  }
}
