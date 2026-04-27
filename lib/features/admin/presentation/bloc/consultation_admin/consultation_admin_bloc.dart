import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/consultation_admin_entity.dart';
import '../../../domain/usecases/consultation_admin/get_consultations_usecase.dart';
import '../../../domain/usecases/consultation_admin/create_consultation_usecase.dart';
import '../../../domain/usecases/consultation_admin/update_consultation_usecase.dart';
import '../../../domain/usecases/consultation_admin/delete_consultation_usecase.dart';
import 'consultation_admin_event.dart';
import 'consultation_admin_state.dart';

class ConsultationAdminBloc extends Bloc<ConsultationAdminEvent, ConsultationAdminState> {
  final GetConsultationsUseCase getConsultationsUseCase;
  final CreateConsultationUseCase createConsultationUseCase;
  final UpdateConsultationUseCase updateConsultationUseCase;
  final DeleteConsultationUseCase deleteConsultationUseCase;

  ConsultationAdminBloc({
    required this.getConsultationsUseCase,
    required this.createConsultationUseCase,
    required this.updateConsultationUseCase,
    required this.deleteConsultationUseCase,
  }) : super(const ConsultationAdminState()) {
    on<LoadConsultations>(_onLoad);
    on<SearchConsultations>(_onSearch);
    on<CreateConsultationRequested>(_onCreate);
    on<UpdateConsultationRequested>(_onUpdate);
    on<DeleteConsultationRequested>(_onDelete);
    on<FilterByProfessional>(_onFilterByProfessional);
    on<FilterByDateRange>(_onFilterByDateRange);
    on<ClearFilters>(_onClearFilters);
    on<LoadMoreConsultations>(_onLoadMore);
  }

  Future<void> _onLoad(LoadConsultations event, Emitter<ConsultationAdminState> emit) async {
    emit(state.copyWith(status: ConsultationAdminStatus.loading));
    final result = await getConsultationsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: ConsultationAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (items) {
        final sorted = items.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        emit(state.copyWith(
          status: ConsultationAdminStatus.loaded,
          items: sorted,
          filteredItems: sorted,
          displayCount: ConsultationAdminState.pageSize,
        ));
      },
    );
  }

  void _onSearch(SearchConsultations event, Emitter<ConsultationAdminState> emit) {
    final newState = state.copyWith(searchQuery: event.query, displayCount: ConsultationAdminState.pageSize);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByProfessional(FilterByProfessional event, Emitter<ConsultationAdminState> emit) {
    final newState = state.copyWith(
      filterProfessional: event.professional,
      clearProfessional: event.professional == null,
      displayCount: ConsultationAdminState.pageSize,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByDateRange(FilterByDateRange event, Emitter<ConsultationAdminState> emit) {
    final newState = state.copyWith(
      filterDateStart: event.start,
      filterDateEnd: event.end,
      clearDateStart: event.start == null,
      clearDateEnd: event.end == null,
      displayCount: ConsultationAdminState.pageSize,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(ClearFilters event, Emitter<ConsultationAdminState> emit) {
    final newState = state.copyWith(
      searchQuery: '',
      clearProfessional: true,
      clearDateStart: true,
      clearDateEnd: true,
      displayCount: ConsultationAdminState.pageSize,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  void _onLoadMore(LoadMoreConsultations event, Emitter<ConsultationAdminState> emit) {
    if (!state.hasMore) return;
    emit(state.copyWith(
      displayCount: state.displayCount + ConsultationAdminState.pageSize,
    ));
  }

  List<ConsultationAdminEntity> _applyFilters(ConsultationAdminState s) {
    var result = s.items.toList();

    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result.where((item) =>
          item.title.toLowerCase().contains(query) ||
          item.professionalName.toLowerCase().contains(query) ||
          item.userName.toLowerCase().contains(query)).toList();
    }

    if (s.filterProfessional != null) {
      result = result.where((item) => item.professionalName == s.filterProfessional).toList();
    }

    if (s.filterDateStart != null) {
      result = result.where((item) =>
          !item.date.isBefore(s.filterDateStart!)).toList();
    }

    if (s.filterDateEnd != null) {
      final endOfDay = DateTime(s.filterDateEnd!.year, s.filterDateEnd!.month, s.filterDateEnd!.day, 23, 59, 59);
      result = result.where((item) =>
          !item.date.isAfter(endOfDay)).toList();
    }

    return result;
  }

  Future<void> _onCreate(CreateConsultationRequested event, Emitter<ConsultationAdminState> emit) async {
    emit(state.copyWith(status: ConsultationAdminStatus.saving));
    final result = await createConsultationUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ConsultationAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ConsultationAdminStatus.saved));
        add(LoadConsultations());
      },
    );
  }

  Future<void> _onUpdate(UpdateConsultationRequested event, Emitter<ConsultationAdminState> emit) async {
    emit(state.copyWith(status: ConsultationAdminStatus.saving));
    final result = await updateConsultationUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ConsultationAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ConsultationAdminStatus.saved));
        add(LoadConsultations());
      },
    );
  }

  Future<void> _onDelete(DeleteConsultationRequested event, Emitter<ConsultationAdminState> emit) async {
    emit(state.copyWith(status: ConsultationAdminStatus.deleting));
    final result = await deleteConsultationUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ConsultationAdminStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ConsultationAdminStatus.deleted));
        add(LoadConsultations());
      },
    );
  }
}
