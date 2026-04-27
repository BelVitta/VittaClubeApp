import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<NextPagePressed>(_onNextPagePressed);
    on<PreviousPagePressed>(_onPreviousPagePressed);
    on<SkipPressed>(_onSkipPressed);
    on<OnboardingCompleted>(_onOnboardingCompleted);
    on<PageSwiped>(_onPageSwiped);
  }

  void _onNextPagePressed(
    NextPagePressed event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isLastPage) {
      emit(const OnboardingComplete());
    } else {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void _onPreviousPagePressed(
    PreviousPagePressed event,
    Emitter<OnboardingState> emit,
  ) {
    if (!state.isFirstPage) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void _onSkipPressed(
    SkipPressed event,
    Emitter<OnboardingState> emit,
  ) {
    emit(const OnboardingComplete());
  }

  void _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) {
    emit(const OnboardingComplete());
  }

  void _onPageSwiped(
    PageSwiped event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(currentPage: event.pageIndex));
  }
}
