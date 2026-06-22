import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/app_lock/domain/entities/lock_type.dart';
import 'package:routine/features/app_lock/presentation/bloc/lock_bloc.dart';
import 'pin_lock_screen.dart';
import 'security_question_page.dart';

// ─── Palette ────────────────────────────────────────────────────────────
// One place for every color so the screen reads as one deliberate design.
const _bgTop = Color(0xFFFFE3D6);
const _bgMid = Color(0xFFF6DCEF);
const _bgBottom = Color(0xFFE2E2FB);
const _ink = Color(0xFF2B2640);
const _inkSoft = Color(0xFF8C8696);

class _LockOptionData {
  const _LockOptionData({
    required this.type,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.accentSoft,
  });

  final LockType type;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final Color accentSoft;
}

const _options = <_LockOptionData>[
  _LockOptionData(
    type: LockType.none,
    icon: Icons.lock_open_rounded,
    label: 'No Lock',
    subtitle: 'Your diary opens right away',
    accent: Color(0xFF9AA0A8),
    accentSoft: Color(0xFFEDEDF2),
  ),
  _LockOptionData(
    type: LockType.biometric,
    icon: Icons.fingerprint_rounded,
    label: 'Mobile Lock',
    subtitle: 'Use your device face or fingerprint',
    accent: Color(0xFF7C8CFF),
    accentSoft: Color(0xFFE2E6FF),
  ),
  _LockOptionData(
    type: LockType.pin,
    icon: Icons.password_rounded,
    label: 'PIN Lock',
    subtitle: 'Unlock with a 4-digit code',
    accent: Color(0xFFFF6F91),
    accentSoft: Color(0xFFFFDCE5),
  ),
  _LockOptionData(
    type: LockType.securityQuestion,
    icon: Icons.question_answer_rounded,
    label: 'Security Question',
    subtitle: 'Unlock by answering your question',
    accent: Color(0xFFB68CFF),
    accentSoft: Color(0xFFEDE3FF),
  ),
];

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
        _showSnackBar(
          'Biometric not supported on this device or add a lock for the device first',
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
        child: BlocConsumer<AppLockBloc, AppLockState>(
          listener: (context, state) {
            if (state.error != null) {
              _showSnackBar('Error: ${state.error}');
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: _ink),
              );
            }

            return SafeArea(
              child: Column(
                children: [
                  _Header(onBack: () => Navigator.maybePop(context)),

                  const SizedBox(height: 18),
                  Expanded(
                    child: ClipPath(
                      clipper: _CloudTopClipper(),
                      child: Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 42, 20, 20),
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final option = _options[index];
                            return _LockOptionTile(
                              data: option,
                              selected: state.lockType == option.type,
                              onTap: () => _onSelectLockType(option.type),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: _ink,
                  ),
                ),
                Text(
                  'your thoughts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card-style list tile inside the white panel ───────────────────────
class _LockOptionTile extends StatelessWidget {
  const _LockOptionTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _LockOptionData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? data.accentSoft : const Color(0xFFFAFAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? data.accent.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(data.icon, color: data.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: const TextStyle(fontSize: 12.5, color: _inkSoft),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.accent,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: _inkSoft.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wavy "cloud horizon" top edge for the white panel ─────────────────
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
