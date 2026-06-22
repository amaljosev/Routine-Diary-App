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

  bool _canAuthenticate = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    if (widget.isVerification) {
      _loadQuestion();
    }
    _initCanAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initCanAuth() async {
    final repo = context.read<AppLockBloc>().repository;
    try {
      final can = await repo.canAuthenticate();
      if (mounted) {
        setState(() {
          _canAuthenticate = can;
          _checkingAuth = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _canAuthenticate = false;
          _checkingAuth = false;
        });
      }
    }
  }

  Future<void> _loadQuestion() async {
    final data = await context.read<AppLockBloc>().repository.getSecurityData();
    if (data != null && mounted) {
      setState(() => _question = data['question']);
    }
  }

  void _submit() {
    if (!widget.isVerification) {
      final question = _question?.trim() ?? '';
      if (question.isEmpty) {
        setState(() => _error = 'Please enter a question');
        return;
      }
      final answer = _controller.text.trim();
      if (answer.isEmpty) {
        setState(() => _error = 'Please enter an answer');
        return;
      }
      Navigator.pop(context, {'question': question, 'answer': answer});
    } else {
      context.read<AppLockBloc>().add(
        VerifyAppSecurityAnswer(_controller.text.trim()),
      );
    }
  }

  void _onForgotPressed() {
    context.read<AppLockBloc>().add(const SwitchToBiometricLock());
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
          return _buildScaffold(theme, colorScheme);
        },
      );
    }
    return _buildScaffold(theme, colorScheme);
  }

  Widget _buildScaffold(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Soft gradient world shared with the rest of the lock flow,
          // derived from the theme so it adapts to light/dark automatically.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.9),
                  colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                  colorScheme.surface,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          FloatingParticles(color: colorScheme.primary),
          _buildContent(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final isVerification = widget.isVerification;

    return SafeArea(
      child: Column(
        children: [
          _Header(
            title: isVerification ? 'Verify Question' : 'Set a Question',
            colorScheme: colorScheme,
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ClipPath(
              clipper: _CloudTopClipper(),
              child: Container(
                width: double.infinity,
                color: colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isVerification) ...[
                        if (_question != null)
                          _QuestionBubble(
                            question: _question!,
                            colorScheme: colorScheme,
                            theme: theme,
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        const SizedBox(height: 8),
                        if (_canAuthenticate && !_checkingAuth)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _onForgotPressed,
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Forgot? Tap here!',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ] else ...[
                        _FieldLabel('Your question', colorScheme),
                        const SizedBox(height: 10),
                        _PillTextField(
                          hint: 'eg: What is your favorite color?',
                          colorScheme: colorScheme,
                          theme: theme,
                          onChanged: (v) => _question = v,
                        ),
                        const SizedBox(height: 22),
                      ],
                      _FieldLabel(
                        isVerification ? 'Your answer' : 'Answer',
                        colorScheme,
                      ),
                      const SizedBox(height: 10),
                      _PillTextField(
                        controller: _controller,
                        hint: 'eg: Red',
                        obscureText: !isVerification,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ErrorPill(message: _error, colorScheme: colorScheme),
                      ],
                      const SizedBox(height: 28),
                      _SubmitButton(
                        label: isVerification ? 'Verify' : 'Continue',
                        colorScheme: colorScheme,
                        theme: theme,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.colorScheme,
    required this.onBack,
  });

  final String title;
  final ColorScheme colorScheme;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 24, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── "Speech bubble" showing the stored question in verify mode ───────
class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({
    required this.question,
    required this.colorScheme,
    required this.theme,
  });

  final String question;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
            ),
            child: Icon(
              Icons.question_answer_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.colorScheme);

  final String text;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ─── Rounded "pill" text field ──────────────────────────────────────────
class _PillTextField extends StatelessWidget {
  const _PillTextField({
    required this.colorScheme,
    required this.theme,
    this.controller,
    this.hint,
    this.onChanged,
    this.obscureText = false,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscureText,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
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

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.message, required this.colorScheme});

  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.colorScheme,
    required this.theme,
    required this.onPressed,
  });

  final String label;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 6,
        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
      ),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Wavy "cloud horizon" top edge, matching the rest of the lock flow ─
class _CloudTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 26);
    path.quadraticBezierTo(size.width * 0.12, 4, size.width * 0.25, 16);
    path.quadraticBezierTo(size.width * 0.38, 30, size.width * 0.5, 12);
    path.quadraticBezierTo(size.width * 0.62, 0, size.width * 0.75, 18);
    path.quadraticBezierTo(size.width * 0.88, 32, size.width, 8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}