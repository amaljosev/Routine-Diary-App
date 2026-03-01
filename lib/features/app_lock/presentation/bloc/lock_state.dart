part of 'lock_bloc.dart';

enum AppVerificationStatus { idle, success, failure }

class AppLockState extends Equatable {
  final LockType lockType;
  final bool isLoading;
  final bool isLocked;
  final AppVerificationStatus verificationStatus;
  final bool verificationInProgress;      
  final String? verificationError;        
  final String? error;

  const AppLockState({
    required this.lockType,
    required this.isLoading,
    required this.isLocked,
    required this.verificationStatus,
    this.verificationInProgress = false,
    this.verificationError,
    this.error,
  });

  factory AppLockState.initial() {
    return const AppLockState(
      lockType: LockType.none,
      isLoading: false,
      isLocked: false,
      verificationStatus: AppVerificationStatus.idle,
      verificationInProgress: false,
      verificationError: null,
      error: null,
    );
  }

  AppLockState copyWith({
    LockType? lockType,
    bool? isLoading,
    bool? isLocked,
    AppVerificationStatus? verificationStatus,
    bool? verificationInProgress,
    String? verificationError,
    String? error,
  }) {
    return AppLockState(
      lockType: lockType ?? this.lockType,
      isLoading: isLoading ?? this.isLoading,
      isLocked: isLocked ?? this.isLocked,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationInProgress: verificationInProgress ?? this.verificationInProgress,
      verificationError: verificationError,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    lockType,
    isLoading,
    isLocked,
    verificationStatus,
    verificationInProgress,
    verificationError,
    error,
  ];
}