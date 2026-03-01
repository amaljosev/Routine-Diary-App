import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/onboarding_repository.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingBloc({required OnboardingRepository repository})
      : _repository = repository,
        super(OnboardingInitial(totalPages: 3)) {
    on<OnboardingStarted>(_onStarted);
    on<NextPageTapped>(_onNextPage);
    on<SkipToEndTapped>(_onSkipToEnd);
    on<GetStartedTapped>(_onGetStarted);
    on<PageChanged>(_onPageChanged);
  }

  void _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) {
    emit(OnboardingLoaded(
      currentPage: 0,
      totalPages: state.totalPages,
    ));
  }

  void _onNextPage(
    NextPageTapped event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is OnboardingLoaded) {
      final nextPage = currentState.currentPage + 1;
      if (nextPage < currentState.totalPages) {
        emit(currentState.copyWith(currentPage: nextPage));
      }
    }
  }

  void _onSkipToEnd(
    SkipToEndTapped event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is OnboardingLoaded) {
      emit(currentState.copyWith(
        currentPage: currentState.totalPages - 1,
      ));
    }
  }

  Future<void> _onGetStarted(
    GetStartedTapped event,
    Emitter<OnboardingState> emit,
  ) async {
    await _repository.setOnboardingCompleted();
    emit(OnboardingCompleted(totalPages: state.totalPages));
  }

  void _onPageChanged(
    PageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    final currentState = state;
    if (currentState is OnboardingLoaded) {
      emit(currentState.copyWith(currentPage: event.pageIndex));
    }
  }
}