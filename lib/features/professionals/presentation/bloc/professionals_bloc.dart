import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_active_professionals_usecase.dart';
import 'professionals_event.dart';
import 'professionals_state.dart';

class ProfessionalsBloc extends Bloc<ProfessionalsEvent, ProfessionalsState> {
  final GetActiveProfessionalsUseCase getProfessionalsUseCase;

  ProfessionalsBloc({required this.getProfessionalsUseCase})
      : super(const ProfessionalsInitial()) {
    on<LoadProfessionals>(_onLoad);
  }

  Future<void> _onLoad(
    LoadProfessionals event,
    Emitter<ProfessionalsState> emit,
  ) async {
    emit(const ProfessionalsLoading());
    final result = await getProfessionalsUseCase();
    result.fold(
      (failure) => emit(ProfessionalsError(failure.message)),
      (items) => emit(ProfessionalsLoaded(items)),
    );
  }
}
