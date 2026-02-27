import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/domain/entities/lock_type.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import 'lock_page.dart';
import 'security_question_page.dart';

class AppLockSettingsPage extends StatefulWidget {
  const AppLockSettingsPage({super.key});

  @override
  State<AppLockSettingsPage> createState() => _AppLockSettingsPageState();
}

class _AppLockSettingsPageState extends State<AppLockSettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AppLockBloc>().add(LoadAppLockSettings());
  }

  Future<void> _onSelectLockType(LockType type) async {
    final bloc = context.read<AppLockBloc>();
    final currentType = bloc.state.lockType;

    if (type == currentType) return;

    if (type == LockType.biometric) {
      final canAuth = await bloc.repository.canAuthenticate();
      if (!canAuth) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric not supported on this device')),
        );
        return;
      }
      final success = await bloc.repository.authenticate(
        reason: 'Authenticate to enable biometric lock',
      );
      if (!success) return;
      bloc.add(const SetAppLockType(type: LockType.biometric));
    } else if (type == LockType.pin) {
      final pin = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LockPage(mode: LockMode.create)),
      );
      if (pin == null) return;
      bloc.add(SetAppLockType(type: type, pin: pin));
    } else if (type == LockType.securityQuestion) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SecurityQuestionPage(isVerification: false),
        ),
      );
      if (result == null) return;
      bloc.add(SetAppLockType(
        type: type,
        question: result['question'],
        answer: result['answer'],
      ));
    } else {
      bloc.add(SetAppLockType(type: type));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Lock Settings')),
      body: BlocConsumer<AppLockBloc, AppLockState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RadioListTile<LockType>(
                title: const Text('No Lock'),
                value: LockType.none,
                groupValue: state.lockType,
                onChanged: (v) => _onSelectLockType(v!),
              ),
              RadioListTile<LockType>(
                title: const Text('Biometric Lock'),
                value: LockType.biometric,
                groupValue: state.lockType,
                onChanged: (v) => _onSelectLockType(v!),
              ),
              RadioListTile<LockType>(
                title: const Text('PIN Lock'),
                value: LockType.pin,
                groupValue: state.lockType,
                onChanged: (v) => _onSelectLockType(v!),
              ),
              RadioListTile<LockType>(
                title: const Text('Security Question Lock'),
                value: LockType.securityQuestion,
                groupValue: state.lockType,
                onChanged: (v) => _onSelectLockType(v!),
              ),
            ],
          );
        },
      ),
    );
  }
}