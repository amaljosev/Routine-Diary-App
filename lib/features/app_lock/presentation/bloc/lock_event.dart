part of 'lock_bloc.dart';

abstract class AppLockEvent extends Equatable {
  const AppLockEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppLockSettings extends AppLockEvent {}

class SetAppLockType extends AppLockEvent {
  final LockType type;
  final String? pin;
  final String? question;
  final String? answer;

  const SetAppLockType({
    required this.type,
    this.pin,
    this.question,
    this.answer,
  });

  @override
  List<Object?> get props => [type, pin, question, answer];
}

class LockApp extends AppLockEvent {}

class UnlockApp extends AppLockEvent {}

class VerifyAppPin extends AppLockEvent {
  final String pin;
  const VerifyAppPin(this.pin);

  @override
  List<Object> get props => [pin];
}

class VerifyAppSecurityAnswer extends AppLockEvent {
  final String answer;
  const VerifyAppSecurityAnswer(this.answer);

  @override
  List<Object> get props => [answer];
}

class VerifyAppBiometric extends AppLockEvent {
  final String reason;
  const VerifyAppBiometric({this.reason = 'Authenticate to continue'});

  @override
  List<Object?> get props => [reason];
}

class ResetAppVerification extends AppLockEvent {}
class SwitchToBiometricLock extends AppLockEvent {
  const SwitchToBiometricLock();
}