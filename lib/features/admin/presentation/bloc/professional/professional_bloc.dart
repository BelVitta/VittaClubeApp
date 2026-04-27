import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/professional_entity.dart';
import '../../../domain/usecases/professional/get_professionals_usecase.dart';
import '../../../domain/usecases/professional/create_professional_usecase.dart';
import '../../../domain/usecases/professional/update_professional_usecase.dart';
import '../../../domain/usecases/professional/delete_professional_usecase.dart';
import 'professional_event.dart';
import 'professional_state.dart';

class ProfessionalBloc extends Bloc<ProfessionalEvent, ProfessionalState> {
  final GetProfessionalsUseCase getProfessionalsUseCase;
  final CreateProfessionalUseCase createProfessionalUseCase;
  final UpdateProfessionalUseCase updateProfessionalUseCase;
  final DeleteProfessionalUseCase deleteProfessionalUseCase;

  ProfessionalBloc({
    required this.getProfessionalsUseCase,
    required this.createProfessionalUseCase,
    required this.updateProfessionalUseCase,
    required this.deleteProfessionalUseCase,
  }) : super(const ProfessionalState()) {
    on<LoadProfessionals>(_onLoad);
    on<SearchProfessionals>(_onSearch);
    on<CreateProfessionalRequested>(_onCreate);
    on<UpdateProfessionalRequested>(_onUpdate);
    on<DeleteProfessionalRequested>(_onDelete);
    on<FilterProfessionalsBySpecialty>(_onFilterBySpecialty);
    on<FilterProfessionalsByStatus>(_onFilterByStatus);
    on<ClearProfessionalFilters>(_onClearFilters);
  }

  Future<void> _onLoad(LoadProfessionals event, Emitter<ProfessionalState> emit) async {
    emit(state.copyWith(status: ProfessionalStatus.loading));
    final result = await getProfessionalsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfessionalStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: ProfessionalStatus.loaded,
        items: items,
        filteredItems: items,
      )),
    );
  }

  void _onSearch(SearchProfessionals event, Emitter<ProfessionalState> emit) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterBySpecialty(FilterProfessionalsBySpecialty event, Emitter<ProfessionalState> emit) {
    final newState = state.copyWith(
      filterSpecialty: event.specialty,
      clearSpecialty: event.specialty == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onFilterByStatus(FilterProfessionalsByStatus event, Emitter<ProfessionalState> emit) {
    final newState = state.copyWith(
      filterIsActive: event.isActive,
      clearIsActive: event.isActive == null,
    );
    emit(newState.copyWith(filteredItems: _applyFilters(newState)));
  }

  void _onClearFilters(ClearProfessionalFilters event, Emitter<ProfessionalState> emit) {
    final newState = state.copyWith(
      searchQuery: '',
      clearSpecialty: true,
      clearIsActive: true,
    );
    emit(newState.copyWith(filteredItems: newState.items));
  }

  List<ProfessionalEntity> _applyFilters(ProfessionalState s) {
    var result = s.items.toList();

    if (s.searchQuery.isNotEmpty) {
      final query = s.searchQuery.toLowerCase();
      result = result.where((item) =>
          item.name.toLowerCase().contains(query) ||
          item.specialtyName.toLowerCase().contains(query)).toList();
    }

    if (s.filterSpecialty != null) {
      result = result.where((item) => item.specialtyName == s.filterSpecialty).toList();
    }

    if (s.filterIsActive != null) {
      result = result.where((item) => item.isActive == s.filterIsActive).toList();
    }

    return result;
  }

  Future<void> _onCreate(CreateProfessionalRequested event, Emitter<ProfessionalState> emit) async {
    emit(state.copyWith(status: ProfessionalStatus.saving));
    final result = await createProfessionalUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfessionalStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ProfessionalStatus.saved));
        add(LoadProfessionals());
      },
    );
  }

  Future<void> _onUpdate(UpdateProfessionalRequested event, Emitter<ProfessionalState> emit) async {
    emit(state.copyWith(status: ProfessionalStatus.saving));
    final result = await updateProfessionalUseCase(event.entity);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfessionalStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ProfessionalStatus.saved));
        add(LoadProfessionals());
      },
    );
  }

  Future<void> _onDelete(DeleteProfessionalRequested event, Emitter<ProfessionalState> emit) async {
    emit(state.copyWith(status: ProfessionalStatus.deleting));
    final result = await deleteProfessionalUseCase(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfessionalStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ProfessionalStatus.deleted));
        add(LoadProfessionals());
      },
    );
  }
}
