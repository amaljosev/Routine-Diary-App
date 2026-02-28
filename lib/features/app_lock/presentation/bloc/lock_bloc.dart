import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/domain/entities/lock_type.dart';
import 'package:routine/features/app_lock/domain/repositories/app_lock_repository.dart';

part 'lock_event.dart';
part 'lock_state.dart';

class AppLockBloc extends Bloc<AppLockEvent, AppLockState> {
  final AppLockRepository repository;

  AppLockBloc({required this.repository}) : super(AppLockState.initial()) {
    on<LoadAppLockSettings>(_onLoadSettings);
    on<SetAppLockType>(_onSetLockType);
    on<LockApp>(_onLockApp);
    on<UnlockApp>(_onUnlockApp);
    on<VerifyAppPin>(_onVerifyPin);
    on<VerifyAppSecurityAnswer>(_onVerifySecurityAnswer);
    on<VerifyAppBiometric>(_onVerifyBiometric);
    on<ResetAppVerification>(_onResetVerification);
  }

  Future<void> _onLoadSettings(
    LoadAppLockSettings event,
    Emitter<AppLockState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final type = await repository.getLockType();
      final shouldLock = type != LockType.none;

      emit(state.copyWith(
        lockType: type,
        isLocked: shouldLock,
        isLoading: false,
        verificationStatus: AppVerificationStatus.idle,
      ));

      log("Loaded lock type: $type | shouldLock: $shouldLock");
    } catch (e) {
      log('LoadAppLockSettings error: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSetLockType(
    SetAppLockType event,
    Emitter<AppLockState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      if (event.type == LockType.pin && event.pin != null) {
        await repository.savePin(event.pin!);
      } else if (event.type == LockType.securityQuestion &&
          event.question != null &&
          event.answer != null) {
        await repository.saveSecurityQuestion(
          event.question!,
          event.answer!,
        );
      }

      await repository.setLockType(event.type);

      final type = await repository.getLockType();

      emit(state.copyWith(
        lockType: type,
        isLocked: type != LockType.none,
        isLoading: false,
      ));
    } catch (e) {
      log('SetAppLockType error: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onLockApp(LockApp event, Emitter<AppLockState> emit) {
    if (state.lockType != LockType.none) {
      emit(state.copyWith(
        isLocked: true,
        verificationStatus: AppVerificationStatus.idle,
      ));
    }
  }

  void _onUnlockApp(UnlockApp event, Emitter<AppLockState> emit) {
    emit(state.copyWith(
      isLocked: false,
      verificationStatus: AppVerificationStatus.idle,
    ));
  }

  Future<void> _onVerifyPin(
    VerifyAppPin event,
    Emitter<AppLockState> emit,
  ) async {
    try {
      final savedPin = await repository.getPin();

      if (savedPin == event.pin) {
        emit(state.copyWith(
          verificationStatus: AppVerificationStatus.success,
          isLocked: false,
        ));
      } else {
        emit(state.copyWith(
          verificationStatus: AppVerificationStatus.failure,
        ));
      }
    } catch (e) {
      log('VerifyAppPin error: $e');
      emit(state.copyWith(
        verificationStatus: AppVerificationStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onVerifySecurityAnswer(
  VerifyAppSecurityAnswer event,
  Emitter<AppLockState> emit,
) async {
  try {
    final data = await repository.getSecurityData();
    // Compare case‑insensitively
    if (data != null &&
        data['answer']?.toString().toLowerCase() ==
            event.answer.trim().toLowerCase()) {
      emit(state.copyWith(
        verificationStatus: AppVerificationStatus.success,
        isLocked: false,
      ));
    } else {
      emit(state.copyWith(
        verificationStatus: AppVerificationStatus.failure,
      ));
    }
  } catch (e) {
    log('VerifyAppSecurityAnswer error: $e');
    emit(state.copyWith(
      verificationStatus: AppVerificationStatus.failure,
      error: e.toString(),
    ));
  }
}

  Future<void> _onVerifyBiometric(
    VerifyAppBiometric event,
    Emitter<AppLockState> emit,
  ) async {
    try {
      final success = await repository.authenticate(reason: event.reason);

      if (success) {
        emit(state.copyWith(
          verificationStatus: AppVerificationStatus.success,
          isLocked: false,
        ));
      } else {
        emit(state.copyWith(
          verificationStatus: AppVerificationStatus.failure,
        ));
      }
    } catch (e) {
      log('VerifyAppBiometric error: $e');
      emit(state.copyWith(
        verificationStatus: AppVerificationStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void _onResetVerification(
    ResetAppVerification event,
    Emitter<AppLockState> emit,
  ) {
    emit(state.copyWith(
      verificationStatus: AppVerificationStatus.idle,
      error: null,
    ));
  }
}