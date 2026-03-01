import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/onboarding_repository.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final OnboardingRepository _repository;

  SplashBloc({required OnboardingRepository repository})
      : _repository = repository,
        super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());
    // Wait 2 seconds (animation duration)
    await Future.delayed(const Duration(seconds: 2));
    try {
      final showOnboarding = await _repository.shouldShowOnboarding();
      if (showOnboarding) {
        emit(SplashNavigateToOnboarding());
      } else {
        emit(SplashNavigateToLockGate());
      }
    } catch (e) {
      emit(SplashError(message: e.toString()));
    }
  }
}