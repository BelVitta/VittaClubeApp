import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_dependent_usecase.dart';
import '../../domain/usecases/deactivate_dependent_usecase.dart';
import '../../domain/usecases/get_dependents_usecase.dart';
import 'dependents_event.dart';
import 'dependents_state.dart';

class DependentsBloc extends Bloc<DependentsEvent, DependentsState> {
  final GetDependentsUseCase getDependentsUseCase;
  final CreateDependentUseCase createDependentUseCase;
  final DeactivateDependentUseCase deactivateDependentUseCase;

  DependentsBloc({
    required this.getDependentsUseCase,
    required this.createDependentUseCase,
    required this.deactivateDependentUseCase,
  }) : super(const DependentsState()) {
    on<LoadDependents>(_onLoad);
    on<CreateDependentRequested>(_onCreate);
    on<DeactivateDependentRequested>(_onDeactivate);
  }

  Future<void> _onLoad(
    LoadDependents event,
    Emitter<DependentsState> emit,
  ) async {
    emit(state.copyWith(status: DependentsStatus.loading));
    final result = await getDependentsUseCase(
      GetDependentsParams(
        holderUserId: event.holderUserId,
        cycleReference: event.cycleReference,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DependentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          status: DependentsStatus.loaded,
          items: items,
        ),
      ),
    );
  }

  Future<void> _onCreate(
    CreateDependentRequested event,
    Emitter<DependentsState> emit,
  ) async {
    emit(state.copyWith(status: DependentsStatus.saving));
    final result = await createDependentUseCase(
      CreateDependentParams(
        holderUserId: event.holderUserId,
        name: event.name,
        cpf: event.cpf,
        birthDate: event.birthDate,
        relationship: event.relationship,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DependentsStatus.failure,
          errorMessage: failure.message,
          limitReached: failure.message.contains('Limite'),
        ),
      ),
      (_) => emit(state.copyWith(status: DependentsStatus.saved)),
    );
  }

  Future<void> _onDeactivate(
    DeactivateDependentRequested event,
    Emitter<DependentsState> emit,
  ) async {
    emit(state.copyWith(status: DependentsStatus.saving));
    final result = await deactivateDependentUseCase(
      DeactivateDependentParams(
        holderUserId: event.holderUserId,
        dependentId: event.dependentId,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DependentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: DependentsStatus.saved)),
    );
  }
}
