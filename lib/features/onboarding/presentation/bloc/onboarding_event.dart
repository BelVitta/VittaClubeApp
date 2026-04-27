import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class NextPagePressed extends OnboardingEvent {}

class PreviousPagePressed extends OnboardingEvent {}

class SkipPressed extends OnboardingEvent {}

class OnboardingCompleted extends OnboardingEvent {}

// Evento disparado quando o usuário arrasta (swipe) para outra página
class PageSwiped extends OnboardingEvent {
  final int pageIndex;
  const PageSwiped(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}
