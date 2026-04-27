import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_user_consultations_usecase.dart';
import 'consultation_event.dart';
import 'consultation_state.dart';

class ConsultationBloc extends Bloc<ConsultationEvent, ConsultationState> {
  final GetUserConsultationsUseCase getUserConsultationsUseCase;

  ConsultationBloc({required this.getUserConsultationsUseCase})
      : super(const ConsultationInitial()) {
    on<LoadUserConsultations>(_onLoad);
  }

  Future<void> _onLoad(
    LoadUserConsultations event,
    Emitter<ConsultationState> emit,
  ) async {
    emit(const ConsultationLoading());
    final result = await getUserConsultationsUseCase();
    result.fold(
      (failure) => emit(ConsultationError(failure.message)),
      (list) => emit(ConsultationLoaded(list)),
    );
  }
}
