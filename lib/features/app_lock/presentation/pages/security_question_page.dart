import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/widgets/floating_particles.dart';
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
      if (_question == null || _question!.isEmpty) {
        setState(() => _error = 'Please enter a question');
        return;
      }
      final answer = _controller.text.trim();
      if (answer.isEmpty) {
        setState(() => _error = 'Please enter an answer');
        return;
      }
      Navigator.pop(context, {'question': _question, 'answer': answer});
    } else {
      context.read<AppLockBloc>().add(
        VerifyAppSecurityAnswer(_controller.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isVerification) {
      return BlocConsumer<AppLockBloc, AppLockState>(
        listenWhen: (previous, current) =>
            previous.verificationStatus != current.verificationStatus,
        listener: (context, state) {
          if (state.verificationStatus == AppVerificationStatus.success) {
            // Handled by LockGate
          } else if (state.verificationStatus ==
              AppVerificationStatus.failure) {
            setState(() => _error = 'Wrong answer');
            context.read<AppLockBloc>().add(ResetAppVerification());
          }
        },
        builder: (context, state) {
          return _buildContent(theme, colorScheme);
        },
      );
    }
    return Stack(
      children: [
        _buildContent(theme, colorScheme),
        FloatingParticles(color: colorScheme.primary),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final isVerification = widget.isVerification;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          isVerification ? 'Verify Security Question' : 'Set Security Question',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isVerification && _question != null) ...[
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _question!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (!isVerification) ...[
              const Spacer(flex: 2),
              Text(
                'Create a security question',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                hint: 'eg: What is your favorite color?',
                onChanged: (v) => _question = v,
              ),
              const SizedBox(height: 20),
            ],

            Text(
              isVerification ? 'Enter your answer' : 'Answer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _controller,
              hint: 'eg: Red',
              obscureText: !isVerification,
            ),

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const Spacer(flex: 3),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: Text(
                isVerification ? 'Verify' : 'Continue',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? hint,
    Function(String)? onChanged,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,

        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
