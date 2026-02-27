import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';



enum LockMode { create, verify }

class LockPage extends StatefulWidget {
  final LockMode mode;

  const LockPage({super.key, required this.mode});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  String _entered = '';
  String _firstPin = '';
  String _error = '';

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
            Navigator.pop(context, _entered); // Return PIN when created
          } else {
            setState(() {
              _error = 'PIN mismatch';
              _firstPin = '';
              _entered = '';
            });
          }
        }
      } else {
        // Verify mode - dispatch verification
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

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == LockMode.create;

    if (!isCreate) {
      return BlocConsumer<AppLockBloc, AppLockState>(
        listenWhen: (previous, current) =>
            previous.verificationStatus != current.verificationStatus,
        listener: (context, state) {
          if (state.verificationStatus == AppVerificationStatus.success) {
            // ✅ DO NOT pop – navigation will be handled by LockGate
            // Just reset any local state if needed
          } else if (state.verificationStatus == AppVerificationStatus.failure) {
            setState(() {
              _error = 'Wrong PIN';
              _entered = '';
            });
            // Reset the verification status so the user can try again
            context.read<AppLockBloc>().add(ResetAppVerification());
          }
        },
        builder: (context, state) {
          return _buildContent(isCreate);
        },
      );
    }

    return _buildContent(isCreate);
  }

  Widget _buildContent(bool isCreate) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isCreate ? 'Set PIN' : 'Enter PIN'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isCreate
                ? (_firstPin.isEmpty ? 'Create PIN' : 'Confirm PIN')
                : 'Enter PIN',
            style: const TextStyle(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.all(8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _entered.length ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          _buildKeypad(),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int j = 1; j <= 3; j++) _key('${i * 3 + j}'),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 60),
            _key('0'),
            IconButton(
              icon: const Icon(Icons.backspace, color: Colors.white),
              onPressed: _backspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(String number) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
        onPressed: () => _addDigit(number),
        child: Text(number, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}