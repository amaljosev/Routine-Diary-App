part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

class OnboardingStarted extends OnboardingEvent {}

class NextPageTapped extends OnboardingEvent {}

class SkipToEndTapped extends OnboardingEvent {}

class GetStartedTapped extends OnboardingEvent {}

class PageChanged extends OnboardingEvent {
  final int pageIndex;
  const PageChanged(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
}