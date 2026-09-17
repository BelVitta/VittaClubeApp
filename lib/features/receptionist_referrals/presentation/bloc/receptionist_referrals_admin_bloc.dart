import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/receptionist_referral_entity.dart';
import '../../domain/usecases/correct_referral_attribution_usecase.dart';
import '../../domain/usecases/get_referrals_usecase.dart';
import 'receptionist_referrals_admin_event.dart';
import 'receptionist_referrals_admin_state.dart';

class ReceptionistReferralsAdminBloc extends Bloc<
    ReceptionistReferralsAdminEvent, ReceptionistReferralsAdminState> {
  final GetReceptionistReferralsUseCase getReferralsUseCase;
  final CorrectReferralAttributionUseCase correctReferralAttributionUseCase;

  ReceptionistReferralsAdminBloc({
    required this.getReferralsUseCase,
    required this.correctReferralAttributionUseCase,
  }) : super(const ReceptionistReferralsAdminState()) {
    on<LoadReferrals>(_onLoad);
    on<SearchReferrals>(_onSearch);
    on<CorrectReferralAttributionRequested>(_onCorrect);
  }

  Future<void> _onLoad(
    LoadReferrals event,
    Emitter<ReceptionistReferralsAdminState> emit,
  ) async {
    emit(state.copyWith(
      status: ReceptionistReferralsAdminStatus.loading,
      monthReference: event.monthReference,
      clearMonthReference: event.monthReference == null,
      receptionistId: event.receptionistId,
      clearReceptionistId: event.receptionistId == null,
      referralStatus: event.status,
      clearReferralStatus: event.status == null,
    ));
    final result = await getReferralsUseCase(
      monthReference: event.monthReference,
      receptionistId: event.receptionistId,
      status: event.status,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReceptionistReferralsAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: ReceptionistReferralsAdminStatus.loaded,
        items: items,
        filteredItems: _applySearch(items, state.searchQuery),
      )),
    );
  }

  void _onSearch(
    SearchReferrals event,
    Emitter<ReceptionistReferralsAdminState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredItems: _applySearch(state.items, event.query),
    ));
  }

  Future<void> _onCorrect(
    CorrectReferralAttributionRequested event,
    Emitter<ReceptionistReferralsAdminState> emit,
  ) async {
    emit(state.copyWith(status: ReceptionistReferralsAdminStatus.correcting));
    final result = await correctReferralAttributionUseCase(
      referralId: event.referralId,
      newReceptionistId: event.newReceptionistId,
      reason: event.reason,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReceptionistReferralsAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(
            state.copyWith(status: ReceptionistReferralsAdminStatus.corrected));
        add(LoadReferrals(
          monthReference: state.monthReference,
          receptionistId: state.receptionistId,
          status: state.referralStatus,
        ));
      },
    );
  }

  List<ReceptionistReferralEntity> _applySearch(
    List<ReceptionistReferralEntity> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    final lower = query.toLowerCase();
    return items
        .where((item) =>
            item.referredUserName.toLowerCase().contains(lower) ||
            item.referredUserEmail.toLowerCase().contains(lower))
        .toList();
  }
}
