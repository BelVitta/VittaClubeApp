import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/cancel_dependent_appointment_usecase.dart';
import '../../domain/usecases/create_dependent_appointment_usecase.dart';
import 'dependent_appointment_event.dart';
import 'dependent_appointment_state.dart';

class DependentAppointmentBloc
    extends Bloc<DependentAppointmentEvent, DependentAppointmentState> {
  final CreateDependentAppointmentUseCase createAppointmentUseCase;
  final CancelDependentAppointmentUseCase cancelAppointmentUseCase;

  DependentAppointmentBloc({
    required this.createAppointmentUseCase,
    required this.cancelAppointmentUseCase,
  }) : super(const DependentAppointmentState()) {
    on<CreateDependentAppointmentRequested>(_onCreate);
    on<CancelDependentAppointmentRequested>(_onCancel);
  }

  Future<void> _onCreate(
    CreateDependentAppointmentRequested event,
    Emitter<DependentAppointmentState> emit,
  ) async {
    emit(state.copyWith(status: DependentAppointmentStatusState.loading));
    final result = await createAppointmentUseCase(
      CreateDependentAppointmentParams(
        holderUserId: event.holderUserId,
        beneficiaryType: event.beneficiaryType,
        beneficiaryId: event.beneficiaryId,
        establishmentId: event.establishmentId,
        scheduledAt: event.scheduledAt,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DependentAppointmentStatusState.failure,
          errorMessage: failure.message,
        ),
      ),
      (appointment) => emit(
        state.copyWith(
          status: DependentAppointmentStatusState.created,
          appointment: appointment,
        ),
      ),
    );
  }

  Future<void> _onCancel(
    CancelDependentAppointmentRequested event,
    Emitter<DependentAppointmentState> emit,
  ) async {
    emit(state.copyWith(status: DependentAppointmentStatusState.loading));
    final result = await cancelAppointmentUseCase(
      CancelDependentAppointmentParams(
        holderUserId: event.holderUserId,
        appointmentId: event.appointmentId,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DependentAppointmentStatusState.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(status: DependentAppointmentStatusState.cancelled),
      ),
    );
  }
}
