import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import '../../../diary/presentation/pages/diary_screen.dart';
import '../../domain/entities/lock_type.dart';
import '../pages/pin_lock_screen.dart';
import '../pages/security_question_page.dart';

class LockGate extends StatelessWidget {
  const LockGate({super.key});

  void _goToDiary(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DiaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppLockBloc, AppLockState>(
      listener: (context, state) {
        if (state.verificationStatus == AppVerificationStatus.success) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<AppLockBloc>().add( ResetAppVerification());
        _goToDiary(context);
      }
    });
  }

  if (!state.isLoading && state.lockType == LockType.none) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _goToDiary(context);
      }
    });
  }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.lockType == LockType.none) {
          return const SizedBox.shrink();
        }

        if (!state.isLocked) {
          return const SizedBox.shrink();
        }

        switch (state.lockType) {
          case LockType.biometric:
            return const _BiometricLockGate();
          case LockType.pin:
            return const PinLockScreen(mode: LockMode.verify);
          case LockType.securityQuestion:
            return const SecurityQuestionPage(isVerification: true);
          case LockType.none:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _BiometricLockGate extends StatefulWidget {
  const _BiometricLockGate();

  @override
  State<_BiometricLockGate> createState() => __BiometricLockGateState();
}

class __BiometricLockGateState extends State<_BiometricLockGate> {
  bool _authTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_authTriggered) {
      _authTriggered = true;
      context.read<AppLockBloc>().add(const VerifyAppBiometric());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppLockBloc, AppLockState>(
      listenWhen: (previous, current) =>
          previous.verificationStatus != current.verificationStatus,
      listener: (context, state) {
        // Optional: additional side effects
      },
      builder: (context, state) {
        if (state.verificationInProgress) {
          return _buildLoadingScreen(context);
        }

        if (state.verificationStatus == AppVerificationStatus.failure) {
          return _buildErrorScreen(context, state.verificationError);
        }

        // Fallback (should not happen) – show loading
        return _buildLoadingScreen(context);
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              'Authenticating...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String? error) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.close_outlined,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Failed',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Unable to authenticate. Please try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      child: const Text('Exit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Trigger authentication again
                        context.read<AppLockBloc>().add(
                          const VerifyAppBiometric(reason: 'Unlock app'),
                        );
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}