import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/validate_dependent_qr_usecase.dart';
import '../../domain/usecases/validate_member_qr_usecase.dart';
import 'qr_validation_event.dart';
import 'qr_validation_state.dart';

class QrValidationBloc extends Bloc<QrValidationEvent, QrValidationState> {
  final ValidateDependentQrUseCase validateDependentQrUseCase;
  final ValidateMemberQrUseCase validateMemberQrUseCase;

  QrValidationBloc({
    required this.validateDependentQrUseCase,
    required this.validateMemberQrUseCase,
  }) : super(const QrValidationState()) {
    on<ValidateQrRequested>(_onValidate);
    on<ValidateMemberQrRequested>(_onValidateMember);
  }

  Future<void> _onValidate(
    ValidateQrRequested event,
    Emitter<QrValidationState> emit,
  ) async {
    emit(state.copyWith(status: QrValidationStatus.loading));
    final result = await validateDependentQrUseCase(
      ValidateDependentQrParams(
        qrToken: event.qrToken,
        actorUserId: event.actorUserId,
        establishmentId: event.establishmentId,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: QrValidationStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (validationResult) => emit(
        state.copyWith(
          status: QrValidationStatus.completed,
          result: validationResult,
        ),
      ),
    );
  }

  Future<void> _onValidateMember(
    ValidateMemberQrRequested event,
    Emitter<QrValidationState> emit,
  ) async {
    emit(state.copyWith(status: QrValidationStatus.loading));
    final result = await validateMemberQrUseCase(
      ValidateMemberQrParams(
        userId: event.userId,
        actorUserId: event.actorUserId,
      ),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: QrValidationStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (validationResult) => emit(
        state.copyWith(
          status: QrValidationStatus.completed,
          result: validationResult,
        ),
      ),
    );
  }
}
