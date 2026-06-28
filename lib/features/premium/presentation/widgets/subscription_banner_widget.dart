// lib/features/premium/presentation/widgets/subscription_banner_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:routine/features/premium/presentation/widgets/paywall_sheet.dart';
import 'package:routine/features/settings/presentation/bloc/apptheme_bloc.dart';

/// A banner that sits at the top of DiaryScreen to show subscription status.
///
/// Shows nothing when the user is a free (never-subscribed) user.
/// Shows an "expired" warning card when the subscription has lapsed.
/// Shows a "premium active" card when the user is premium (diary screens only).
class SubscriptionStatusBanner extends StatefulWidget {
  const SubscriptionStatusBanner({super.key, required this.isHome});

  final bool isHome;

  @override
  State<SubscriptionStatusBanner> createState() =>
      _SubscriptionStatusBannerState();
}

class _SubscriptionStatusBannerState extends State<SubscriptionStatusBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PremiumBloc, PremiumState>(
      buildWhen: (prev, curr) =>
          prev.isPremium != curr.isPremium ||
          prev.showExpiredBanner != curr.showExpiredBanner ||
          prev.subscriptionExpired != curr.subscriptionExpired,
      listenWhen: (prev, curr) =>
          !prev.showExpiredBanner && curr.showExpiredBanner,
      listener: (context, state) {
        if (mounted) setState(() => _dismissed = false);

        Future.microtask(() {
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          context.read<PremiumBloc>().add(const PremiumExpiredBannerShown());
        });
      },
      builder: (context, state) {
        if ((state.subscriptionExpired || state.showExpiredBanner) &&
            !_dismissed) {
          return ExpiredBanner(
            onRenewTap: () => showPaywallSheet(
              context,
              onSuccess: () {
                final customModel =
                    context.read<ThemeBloc>().state.customThemeModel;
                if (customModel != null) {
                  context
                      .read<ThemeBloc>()
                      .add(ApplyCustomTheme(customModel));
                }
              },
            ),
            onDismiss: () => setState(() => _dismissed = true),
          );
        }

        if (state.isPremium && !widget.isHome) {
          return const _PremiumActiveBadge();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

/// Dot-pattern background used by both banner variants.
class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const dotSpacing = 20.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += dotSpacing) {
      for (double y = 0; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Shared slide-in + fade-in animation wrapper.
/// [child] is built once and does not rebuild on animation tick.
class _SlideInCard extends StatefulWidget {
  const _SlideInCard({required this.child});

  final Widget child;

  @override
  State<_SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<_SlideInCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  )..forward();

  late final Animation<double> _slide = Tween<double>(begin: -0.3, end: 0)
      .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

  late final Animation<double> _fade = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // Pass child through so it is not rebuilt on every animation frame.
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(_slide.value * 100, 0),
        child: Opacity(opacity: _fade.value, child: child),
      ),
    );
  }
}

/// Shared gradient card container used by both banners.
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.gradientDark,
    required this.gradientLight,
    required this.shadowColor,
    required this.child,
  });

  final List<Color> gradientDark;
  final List<Color> gradientLight;
  final Color shadowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark ? gradientDark : gradientLight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(painter: const _DotPatternPainter()),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Left icon tile used inside both banners.
class _BannerIcon extends StatelessWidget {
  const _BannerIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

// ── Expired banner ────────────────────────────────────────────────────────────

class ExpiredBanner extends StatelessWidget {
  const ExpiredBanner({
    super.key,
    required this.onRenewTap,
    required this.onDismiss,
  });

  final VoidCallback onRenewTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _SlideInCard(
      child: _BannerCard(
        gradientDark: const [Color(0xFF2D1B4E), Color(0xFF1A1A2E)],
        gradientLight: const [Color(0xFF6C3CE1), Color(0xFF4A2C8A)],
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFF6C3CE1).withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const _BannerIcon(icon: Icons.workspace_premium_rounded),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Subscription Expired',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Renew now to keep your premium features',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    label: 'Renew',
                    accentColor: const Color(0xFF6C3CE1),
                    onTap: onRenewTap,
                  ),
                  const SizedBox(width: 8),
                  _DismissButton(onTap: onDismiss),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Premium active badge ──────────────────────────────────────────────────────

class _PremiumActiveBadge extends StatelessWidget {
  const _PremiumActiveBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _SlideInCard(
      child: _BannerCard(
        gradientDark: const [Color(0xFF0D2B1F), Color(0xFF0A1F1A)],
        gradientLight: const [Color(0xFF1B8C5E), Color(0xFF0F6B47)],
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFF1B8C5E).withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const _BannerIcon(icon: Icons.workspace_premium_rounded),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Premium Active',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All features unlocked and ready',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Status pill — same slot as the action buttons in ExpiredBanner
              _ActivePill(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glowing "active" status pill shown on the premium badge.
class _ActivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.greenAccent.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.shade400.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Active',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Shared action widgets ─────────────────────────────────────────────────────

/// White pill button with a coloured label used inside banners.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: accentColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular dismiss (×) button used inside banners.
class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ── Minimal expired design (alternative) ─────────────────────────────────────

class MinimalSubscriptionBanner extends StatelessWidget {
  const MinimalSubscriptionBanner({
    super.key,
    required this.onRenewTap,
    required this.onDismiss,
  });

  final VoidCallback onRenewTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C3E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFE8E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Premium Expired',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Upgrade to continue',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onRenewTap,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3CE1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}