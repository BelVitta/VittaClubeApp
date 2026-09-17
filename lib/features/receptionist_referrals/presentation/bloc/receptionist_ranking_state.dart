import 'package:equatable/equatable.dart';

import '../../domain/entities/receptionist_ranking_entry_entity.dart';

enum ReceptionistRankingStatus { initial, loading, loaded, failure }

class ReceptionistRankingState extends Equatable {
  final ReceptionistRankingStatus status;
  final String monthReference;
  final List<ReceptionistRankingEntryEntity> entries;
  final String? currentUserId;
  final String? errorMessage;

  const ReceptionistRankingState({
    this.status = ReceptionistRankingStatus.initial,
    required this.monthReference,
    this.entries = const [],
    this.currentUserId,
    this.errorMessage,
  });

  /// Linha do admin logado, se ele estiver no ranking (é sempre 'admin',
  /// já que só admins entram no ranking).
  ReceptionistRankingEntryEntity? get ownEntry {
    if (currentUserId == null) return null;
    for (final entry in entries) {
      if (entry.receptionistId == currentUserId) return entry;
    }
    return null;
  }

  ReceptionistRankingState copyWith({
    ReceptionistRankingStatus? status,
    String? monthReference,
    List<ReceptionistRankingEntryEntity>? entries,
    String? currentUserId,
    String? errorMessage,
  }) {
    return ReceptionistRankingState(
      status: status ?? this.status,
      monthReference: monthReference ?? this.monthReference,
      entries: entries ?? this.entries,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, monthReference, entries, currentUserId, errorMessage];
}
