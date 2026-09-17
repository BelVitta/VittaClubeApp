import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../domain/usecases/get_monthly_ranking_usecase.dart';
import 'receptionist_ranking_event.dart';
import 'receptionist_ranking_state.dart';

String currentMonthReference() => DateFormat('yyyy-MM').format(DateTime.now());

class ReceptionistRankingBloc
    extends Bloc<ReceptionistRankingEvent, ReceptionistRankingState> {
  final GetMonthlyRankingUseCase getMonthlyRankingUseCase;

  ReceptionistRankingBloc({required this.getMonthlyRankingUseCase})
      : super(ReceptionistRankingState(
          monthReference: currentMonthReference(),
          currentUserId: SupabaseConfig.isInitialized
              ? SupabaseConfig.client.auth.currentUser?.id
              : null,
        )) {
    on<LoadReceptionistRanking>(_onLoad);
  }

  Future<void> _onLoad(
    LoadReceptionistRanking event,
    Emitter<ReceptionistRankingState> emit,
  ) async {
    final month = event.monthReference ?? state.monthReference;
    emit(state.copyWith(
        status: ReceptionistRankingStatus.loading, monthReference: month));
    final result = await getMonthlyRankingUseCase(month);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReceptionistRankingStatus.failure,
        errorMessage: failure.message,
      )),
      (entries) => emit(state.copyWith(
        status: ReceptionistRankingStatus.loaded,
        entries: entries,
      )),
    );
  }
}
