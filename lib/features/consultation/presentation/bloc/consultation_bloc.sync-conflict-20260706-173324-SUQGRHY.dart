import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_logger.dart';
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
      (failure) {
        AppLogger.warning(
          'Falha ao carregar histórico de consultas.',
          name: 'ConsultationBloc',
          context: {
            'failureType': failure.runtimeType.toString(),
            'message': failure.message,
          },
        );
        emit(const ConsultationError(
          'Erro no servidor. Não foi possível carregar o histórico agora.',
        ));
      },
      (list) => emit(ConsultationLoaded(list)),
    );
  }
}
