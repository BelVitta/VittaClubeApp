import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_badge_progress_usecase.dart';
import '../../domain/usecases/check_badge_upgrade_usecase.dart';
import 'badge_progress_event.dart';
import 'badge_progress_state.dart';

class BadgeProgressBloc
    extends Bloc<BadgeProgressEvent, BadgeProgressState> {
  final GetBadgeProgressUseCase getBadgeProgressUseCase;
  final CheckBadgeUpgradeUseCase checkBadgeUpgradeUseCase;

  BadgeProgressBloc({
    required this.getBadgeProgressUseCase,
    required this.checkBadgeUpgradeUseCase,
  }) : super(const BadgeProgressState()) {
    on<LoadBadgeProgress>(_onLoad);
    on<CheckBadgeUpgrade>(_onCheckUpgrade);
  }

  Future<void> _onLoad(
      LoadBadgeProgress event, Emitter<BadgeProgressState> emit) async {
    emit(state.copyWith(status: BadgeProgressStatus.loading));
    final result = await getBadgeProgressUseCase(event.userId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: BadgeProgressStatus.failure,
        errorMessage: failure.message,
      )),
      (progress) => emit(state.copyWith(
        status: BadgeProgressStatus.loaded,
        progress: progress,
      )),
    );
  }

  Future<void> _onCheckUpgrade(
      CheckBadgeUpgrade event, Emitter<BadgeProgressState> emit) async {
    final previousLevel = state.progress?.currentBadgeLevel;
    emit(state.copyWith(status: BadgeProgressStatus.loading));

    final result = await checkBadgeUpgradeUseCase(event.userId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: BadgeProgressStatus.failure,
        errorMessage: failure.message,
      )),
      (progress) {
        final wasUpgraded = previousLevel != null &&
            previousLevel != progress.currentBadgeLevel;
        emit(state.copyWith(
          status: wasUpgraded
              ? BadgeProgressStatus.upgraded
              : BadgeProgressStatus.loaded,
          progress: progress,
          previousLevel: wasUpgraded ? previousLevel : null,
        ));
      },
    );
  }
}
