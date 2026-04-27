import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/partner_validation/generate_token_usecase.dart';
import '../../../domain/usecases/partner_validation/validate_checkin_usecase.dart';
import 'partner_checkin_event.dart';
import 'partner_checkin_state.dart';

class PartnerCheckinBloc extends Bloc<PartnerCheckinEvent, PartnerCheckinState> {
  final GenerateTokenUseCase generateTokenUseCase;
  final ValidateCheckinUseCase validateCheckinUseCase;

  PartnerCheckinBloc({
    required this.generateTokenUseCase,
    required this.validateCheckinUseCase,
  }) : super(const PartnerCheckinState()) {
    on<GenerateCheckinToken>(_onGenerateToken);
    on<SubmitPartnerCode>(_onSubmitCode);
  }

  Future<void> _onGenerateToken(GenerateCheckinToken event, Emitter<PartnerCheckinState> emit) async {
    emit(state.copyWith(status: PartnerCheckinStatus.generatingToken));
    final result = await generateTokenUseCase(event.userId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerCheckinStatus.failure,
        errorMessage: failure.message,
      )),
      (token) => emit(state.copyWith(
        status: PartnerCheckinStatus.tokenGenerated,
        tokenValue: token,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      )),
    );
  }

  Future<void> _onSubmitCode(SubmitPartnerCode event, Emitter<PartnerCheckinState> emit) async {
    emit(state.copyWith(status: PartnerCheckinStatus.validating));
    final result = await validateCheckinUseCase(
      userId: event.userId,
      token: event.token,
      partnerCode: event.partnerCode,
      serviceId: event.serviceId,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: PartnerCheckinStatus.failure,
        errorMessage: failure.message,
      )),
      (validation) => emit(state.copyWith(
        status: PartnerCheckinStatus.validated,
        validation: validation,
      )),
    );
  }
}
