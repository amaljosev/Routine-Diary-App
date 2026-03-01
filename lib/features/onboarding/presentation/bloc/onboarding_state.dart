part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  final int totalPages;
  const OnboardingState({required this.totalPages});

  @override
  List<Object> get props => [totalPages];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial({required super.totalPages});
}

class OnboardingLoaded extends OnboardingState {
  final int currentPage;
  const OnboardingLoaded({
    required this.currentPage,
    required super.totalPages,
  });

  bool get isLastPage => currentPage == totalPages - 1;

  OnboardingLoaded copyWith({int? currentPage}) {
    return OnboardingLoaded(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages,
    );
  }

  @override
  List<Object> get props => [currentPage, totalPages];
}

class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted({required super.totalPages});
}