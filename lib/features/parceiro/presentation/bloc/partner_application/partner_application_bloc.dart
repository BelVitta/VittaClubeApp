import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../domain/entities/partner_application_entity.dart';
import '../../../domain/usecases/partner_application/approve_partner_application_usecase.dart';
import '../../../domain/usecases/partner_application/get_partner_applications_usecase.dart';
import '../../../domain/usecases/partner_application/reject_partner_application_usecase.dart';
import 'partner_application_event.dart';
import 'partner_application_state.dart';

class PartnerApplicationBloc
    extends Bloc<PartnerApplicationEvent, PartnerApplicationState> {
  final GetPartnerApplicationsUseCase getPartnerApplicationsUseCase;
  final ApprovePartnerApplicationUseCase approvePartnerApplicationUseCase;
  final RejectPartnerApplicationUseCase rejectPartnerApplicationUseCase;

  PartnerApplicationBloc({
    required this.getPartnerApplicationsUseCase,
    required this.approvePartnerApplicationUseCase,
    required this.rejectPartnerApplicationUseCase,
  }) : super(const PartnerApplicationState()) {
    on<LoadPartnerApplications>(_onLoad);
    on<SearchPartnerApplications>(_onSearch);
    on<FilterApplicationsByStatus>(_onFilterByStatus);
    on<FilterApplicationsByCategory>(_onFilterByCategory);
    on<ClearApplicationFilters>(_onClearFilters);
    on<ApprovePartnerApplicationRequested>(_onApprove);
    on<RejectPartnerApplicationRequested>(_onReject);
  }

  Future<void> _onLoad(
    LoadPartnerApplications event,
    Emitter<PartnerApplicationState> emit,
  ) async {
    emit(state.copyWith(status: PartnerApplicationStatus.loading));
    final result = await getPartnerApplicationsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerApplicationStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: PartnerApplicationStatus.loaded,
        items: items,
        filteredItems: _applyFilters(state.copyWith(items: items)),
      )),
    );
  }

  void _onSearch(
    SearchPartnerApplications event,
    Emitter<PartnerApplicationState> emit,
  ) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByStatus(
    FilterApplicationsByStatus event,
    Emitter<PartnerApplicationState> emit,
  ) {
    final newState = state.copyWith(
      filterStatus: event.status,
      clearFilterStatus: event.status == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByCategory(
    FilterApplicationsByCategory event,
    Emitter<PartnerApplicationState> emit,
  ) {
    final newState = state.copyWith(
      filterCategory: event.category,
      clearFilterCategory: event.category == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(
    ClearApplicationFilters event,
    Emitter<PartnerApplicationState> emit,
  ) {
    final newState = state.copyWith(
      searchQuery: '',
      clearFilterStatus: true,
      clearFilterCategory: true,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  List<PartnerApplicationEntity> _applyFilters(PartnerApplicationState s) {
    var result = s.items.toList();
    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result
          .where((item) =>
              item.name.toLowerCase().contains(query) ||
              item.email.toLowerCase().contains(query))
          .toList();
    }
    if (s.filterStatus != null) {
      result = result.where((item) => item.status == s.filterStatus).toList();
    }
    if (s.filterCategory != null) {
      result =
          result.where((item) => item.category == s.filterCategory).toList();
    }
    return result;
  }

  Future<void> _onApprove(
    ApprovePartnerApplicationRequested event,
    Emitter<PartnerApplicationState> emit,
  ) async {
    emit(state.copyWith(status: PartnerApplicationStatus.approving));
    final reviewerId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final result = await approvePartnerApplicationUseCase(event.id,
        reviewerId: reviewerId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerApplicationStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PartnerApplicationStatus.approved));
        add(LoadPartnerApplications());
      },
    );
  }

  Future<void> _onReject(
    RejectPartnerApplicationRequested event,
    Emitter<PartnerApplicationState> emit,
  ) async {
    emit(state.copyWith(status: PartnerApplicationStatus.rejecting));
    final reviewerId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final result = await rejectPartnerApplicationUseCase(
      event.id,
      reviewerId: reviewerId,
      reason: event.reason,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerApplicationStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: PartnerApplicationStatus.rejected));
        add(LoadPartnerApplications());
      },
    );
  }
}
