import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';

enum LockMode { create, verify }

// ─── Palette ────────────────────────────────────────────────────────────
// Matches app_lock_settings_page.dart so the two screens feel like one flow.
const _bgTop = Color(0xFFFFE3D6);
const _bgMid = Color(0xFFF6DCEF);
const _bgBottom = Color(0xFFE2E2FB);
const _ink = Color(0xFF2B2640);
const _inkSoft = Color(0xFF8C8696);
const _accent = Color(
  0xFFFF6F91,
); // PIN lock's accent color from the settings page
const _accentSoft = Color(0xFFFFDCE5);

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

  bool _canAuthenticate = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    // check whether device supports biometric / device authentication
    _initCanAuth();
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

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String d) {
    if (_entered.length >= 4) return;

    setState(() {
      _entered += d;
      _error = '';
    });

    if (_entered.length == 4) {
      if (widget.mode == LockMode.create) {
        if (_firstPin.isEmpty) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (!mounted) return;
            setState(() {
              _firstPin = _entered;
              _entered = '';
            });
          });
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

  void _onForgotPressed() {
    context.read<AppLockBloc>().add(const SwitchToBiometricLock());
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
          } else if (state.verificationStatus ==
              AppVerificationStatus.failure) {
            _showError('Wrong PIN');
            _entered = '';
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
    return Scaffold(
      backgroundColor: _bgBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgMid, _bgBottom],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                title: isCreate
                    ? (_firstPin.isEmpty ? 'Set PIN' : 'Confirm PIN')
                    : 'Enter PIN',
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 6),
              Text(
                isCreate
                    ? (_firstPin.isEmpty
                          ? 'Create a 4-digit PIN'
                          : 'Type it again to confirm')
                    : 'Enter your 4-digit PIN',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _inkSoft,
                ),
              ),
              const SizedBox(height: 28),

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
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? _accent : Colors.white,
                        border: Border.all(
                          color: isFilled ? _accent : _accent.withOpacity(0.35),
                          width: 1.4,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: _accent.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              // Error / forgot row
              SizedBox(
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _error.isNotEmpty
                      ? Center(
                          child: Text(
                            _error,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE4574B),
                            ),
                          ),
                        )
                      : (!isCreate && !_checkingAuth && _canAuthenticate)
                      ? Center(
                          child: TextButton(
                            onPressed: _onForgotPressed,
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Forgot? Tap here!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 4),
              Expanded(
                child: ClipPath(
                  clipper: _CloudTopClipper(),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 44, 20, 12),
                    child: Center(child: _buildKeypad()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildKey('${row * 3 + col}'),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 78), // placeholder to balance the row
              _buildKey('0'),
              _buildBackspaceKey(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String digit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 68,
      height: 68,
      child: Material(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(34),
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: () => _addDigit(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 68,
      height: 68,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(34),
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: _backspace,
          child: const Center(
            child: Icon(Icons.backspace_rounded, size: 24, color: _inkSoft),
          ),
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _ink,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wavy "cloud horizon" top edge for the keypad panel ────────────────
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
