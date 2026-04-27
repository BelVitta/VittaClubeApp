import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_referral_usecase.dart';
import '../../domain/usecases/get_referrals_usecase.dart';
import '../../domain/usecases/validate_referral_usecase.dart';
import '../../domain/usecases/claim_reward_usecase.dart';
import 'referral_event.dart';
import 'referral_state.dart';

class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final GetReferralsUseCase getReferralsUseCase;
  final CreateReferralUseCase createReferralUseCase;
  final ValidateReferralUseCase validateReferralUseCase;
  final ClaimRewardUseCase claimRewardUseCase;

  ReferralBloc({
    required this.getReferralsUseCase,
    required this.createReferralUseCase,
    required this.validateReferralUseCase,
    required this.claimRewardUseCase,
  }) : super(const ReferralState()) {
    on<LoadReferrals>(_onLoad);
    on<CreateReferralRequested>(_onCreate);
    on<ValidateReferralCodeRequested>(_onValidate);
    on<ClaimRewardRequested>(_onClaim);
  }

  Future<void> _onLoad(
      LoadReferrals event, Emitter<ReferralState> emit) async {
    emit(state.copyWith(status: ReferralBlocStatus.loading));
    final result = await getReferralsUseCase(event.userId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReferralBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (referrals) {
        final now = DateTime.now();
        final thisMonth = referrals
            .where((r) =>
                r.createdAt.month == now.month && r.createdAt.year == now.year)
            .length;
        emit(state.copyWith(
          status: ReferralBlocStatus.loaded,
          referrals: referrals,
          referralsThisMonth: thisMonth,
        ));
      },
    );
  }

  Future<void> _onCreate(
      CreateReferralRequested event, Emitter<ReferralState> emit) async {
    emit(state.copyWith(status: ReferralBlocStatus.creating));
    final result = await createReferralUseCase(event.userId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReferralBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (referral) {
        emit(state.copyWith(
          status: ReferralBlocStatus.created,
          lastCreated: referral,
        ));
        add(LoadReferrals(event.userId));
      },
    );
  }

  Future<void> _onValidate(
      ValidateReferralCodeRequested event, Emitter<ReferralState> emit) async {
    emit(state.copyWith(status: ReferralBlocStatus.validating));
    final result =
        await validateReferralUseCase(event.code, event.referredUserId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReferralBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: ReferralBlocStatus.validated)),
    );
  }

  Future<void> _onClaim(
      ClaimRewardRequested event, Emitter<ReferralState> emit) async {
    emit(state.copyWith(status: ReferralBlocStatus.claiming));
    final result = await claimRewardUseCase(event.referralId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReferralBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(status: ReferralBlocStatus.claimed)),
    );
  }
}
