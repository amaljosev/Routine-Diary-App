import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';


class SecurityQuestionPage extends StatefulWidget {
  final bool isVerification;

  const SecurityQuestionPage({super.key, required this.isVerification});

  @override
  State<SecurityQuestionPage> createState() => _SecurityQuestionPageState();
}

class _SecurityQuestionPageState extends State<SecurityQuestionPage> {
  final TextEditingController _controller = TextEditingController();
  String? _question;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.isVerification) {
      _loadQuestion();
    }
  }

  Future<void> _loadQuestion() async {
    final data = await context.read<AppLockBloc>().repository.getSecurityData();
    if (data != null) {
      setState(() => _question = data['question']);
    }
  }

  void _submit() {
    if (!widget.isVerification) {
      // Creation mode – validate and pop with data
      if (_question == null || _question!.isEmpty) {
        setState(() => _error = 'Please enter a question');
        return;
      }
      final answer = _controller.text.trim();
      if (answer.isEmpty) {
        setState(() => _error = 'Please enter an answer');
        return;
      }
      Navigator.pop(context, {
        'question': _question,
        'answer': answer,
      });
    } else {
      // Verification mode – dispatch event
      context.read<AppLockBloc>().add(VerifyAppSecurityAnswer(_controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVerification) {
      return BlocConsumer<AppLockBloc, AppLockState>(
        listenWhen: (previous, current) =>
            previous.verificationStatus != current.verificationStatus,
        listener: (context, state) {
          if (state.verificationStatus == AppVerificationStatus.success) {
            // ✅ DO NOT pop – navigation handled by LockGate
            // Optionally clear any local error state
          } else if (state.verificationStatus == AppVerificationStatus.failure) {
            setState(() {
              _error = 'Wrong answer';
            });
            // Reset the verification status so the user can try again
            context.read<AppLockBloc>().add(ResetAppVerification());
          }
        },
        builder: (context, state) {
          // Show loading indicator if needed (optional)
          return _buildContent();
        },
      );
    }
    return _buildContent();
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isVerification
            ? 'Verify Security Question'
            : 'Set Security Question'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.isVerification && _question != null)
              Text(_question!, style: const TextStyle(fontSize: 18, color: Colors.white)),
            if (!widget.isVerification)
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Question',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
                onChanged: (v) => _question = v,
              ),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Answer',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: _submit,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}