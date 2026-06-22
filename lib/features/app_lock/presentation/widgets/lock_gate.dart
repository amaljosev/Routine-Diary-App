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
              context.read<AppLockBloc>().add(ResetAppVerification());
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
          return const _GlowLoadingScaffold(label: 'Just a moment...');
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
          return const _GlowLoadingScaffold(label: 'Looking for you...');
        }

        if (state.verificationStatus == AppVerificationStatus.failure) {
          return _ErrorScaffold(
            error: state.verificationError,
            onRetry: () => context.read<AppLockBloc>().add(
              const VerifyAppBiometric(reason: 'Unlock app'),
            ),
          );
        }

        // Fallback (should not happen) – show loading
        return const _GlowLoadingScaffold(label: 'Looking for you...');
      },
    );
  }
}

// ─── Loading state: a soft, breathing glow orb instead of a spinner ────
class _GlowLoadingScaffold extends StatefulWidget {
  const _GlowLoadingScaffold({required this.label});

  final String label;

  @override
  State<_GlowLoadingScaffold> createState() => _GlowLoadingScaffoldState();
}

class _GlowLoadingScaffoldState extends State<_GlowLoadingScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_controller.value);
                final scale = 0.9 + (t * 0.18);
                final glow = 0.25 + (t * 0.35);
                return Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: base.withValues(alpha: glow),
                        blurRadius: 50,
                        spreadRadius: 14,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            base.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state: a friendly card, not an alarming red screen ──────────
class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 38,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Couldn't recognize you",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Unable to authenticate. Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => SystemNavigator.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF14121F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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