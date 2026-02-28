import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';

enum LockMode { create, verify }

class PinLockScreen extends StatefulWidget {
  final LockMode mode;

  const PinLockScreen({super.key, required this.mode});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  String _entered = '';
  String _firstPin = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String d) {
    if (_entered.length >= 4) return;

    setState(() => _entered += d);

    if (_entered.length == 4) {
      if (widget.mode == LockMode.create) {
        if (_firstPin.isEmpty) {
          _firstPin = _entered;
          _entered = '';
          setState(() {});
        } else {
          if (_firstPin == _entered) {
            Navigator.pop(context, _entered);
          } else {
            _showError('PIN mismatch');
            _firstPin = '';
            _entered = '';
          }
        }
      } else {
        context.read<AppLockBloc>().add(VerifyAppPin(_entered));
      }
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
    });
  }

  void _showError(String message) {
    setState(() => _error = message);
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == LockMode.create;

    if (!isCreate) {
      return BlocConsumer<AppLockBloc, AppLockState>(
        listenWhen: (previous, current) =>
            previous.verificationStatus != current.verificationStatus,
        listener: (context, state) {
          if (state.verificationStatus == AppVerificationStatus.success) {
            // Handled by LockGate – do nothing here
          } else if (state.verificationStatus == AppVerificationStatus.failure) {
            _showError('Wrong PIN');
            context.read<AppLockBloc>().add(ResetAppVerification());
          }
        },
        builder: (context, state) {
          return _buildContent(context, isCreate);
        },
      );
    }

    return _buildContent(context, isCreate);
  }

  Widget _buildContent(BuildContext context, bool isCreate) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          isCreate ? 'Set PIN' : 'Enter PIN',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Instruction text
              Text(
                isCreate
                    ? (_firstPin.isEmpty ? 'Create a 4-digit PIN' : 'Confirm your PIN')
                    : 'Enter your 4-digit PIN',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),

              // Animated pin dots
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _entered.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      child: isFilled
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    );
                  }),
                ),
              ),

              // Error message
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const Spacer(flex: 3),

              // Keypad
              _buildKeypad(theme, colorScheme),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildKey('${row * 3 + col}', theme, colorScheme),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 80), // placeholder
              _buildKey('0', theme, colorScheme),
              _buildBackspaceKey(theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 70,
      height: 70,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) ,
        borderRadius: BorderRadius.circular(35),
        elevation: 2,
        shadowColor: colorScheme.shadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: () => _addDigit(digit),
          child: Center(
            child: Text(
              digit,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 70,
      height: 70,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(35),
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: _backspace,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 28,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}