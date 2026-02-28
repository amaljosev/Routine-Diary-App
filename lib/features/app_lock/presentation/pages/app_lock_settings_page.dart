import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/domain/entities/lock_type.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import 'pin_lock_screen.dart';
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
        _showSnackBar('Biometric not supported on this device');
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
        MaterialPageRoute(
          builder: (_) => const PinLockScreen(mode: LockMode.create),
        ),
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
      bloc.add(
        SetAppLockType(
          type: type,
          question: result['question'],
          answer: result['answer'],
        ),
      );
    } else {
      bloc.add(SetAppLockType(type: type));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AppLockBloc, AppLockState>(
        listener: (context, state) {
          if (state.error != null) {
            _showSnackBar('Error: ${state.error}');
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).primaryColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                title: const Text('Diary Lock'),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  CupertinoListSection.insetGrouped(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    children: [
                      _buildLockOption(
                        context,
                        type: LockType.none,
                        icon: Icons.lock_open_outlined,
                        label: 'No Lock',
                        selected: state.lockType == LockType.none,
                      ),
                      _buildLockOption(
                        context,
                        type: LockType.biometric,
                        icon: Icons.fingerprint,
                        label: 'Biometric Lock',
                        selected: state.lockType == LockType.biometric,
                      ),
                      _buildLockOption(
                        context,
                        type: LockType.pin,
                        icon: Icons.pin_outlined,
                        label: 'PIN Lock',
                        selected: state.lockType == LockType.pin,
                      ),
                      _buildLockOption(
                        context,
                        type: LockType.securityQuestion,
                        icon: Icons.question_answer_outlined,
                        label: 'Security Question Lock',
                        selected: state.lockType == LockType.securityQuestion,
                      ),
                    ],
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLockOption(
    BuildContext context, {
    required LockType type,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(label, style: theme.textTheme.titleSmall),
      trailing: selected ? Icon(Icons.check, color: theme.primaryColor) : null,
      onTap: () => _onSelectLockType(type),
    );
  }
}
