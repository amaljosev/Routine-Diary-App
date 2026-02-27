import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import '../../../diary/presentation/pages/diary_screen.dart';
import '../../domain/entities/lock_type.dart';
import '../pages/lock_page.dart';
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
        // Handle successful verification
        if (state.verificationStatus == AppVerificationStatus.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _goToDiary(context);
            }
          });
        }

        // Handle no lock type
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
            return const LockPage(mode: LockMode.verify);
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
  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    context.read<AppLockBloc>().add(const VerifyAppBiometric());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('Authenticating...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}