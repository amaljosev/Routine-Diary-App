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
/// Shows a subtle "premium active" chip when the user is premium.
class SubscriptionStatusBanner extends StatefulWidget {
  const SubscriptionStatusBanner({super.key});

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
        // Reset dismissed flag on a fresh expiry event so the banner
        // reappears if the subscription expires mid-session.
        if (mounted) setState(() => _dismissed = false);

        // Guard with mounted before using context across the async gap.
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
                final customModel = context
                    .read<ThemeBloc>()
                    .state
                    .customThemeModel;
                if (customModel != null) {
                  context.read<ThemeBloc>().add(ApplyCustomTheme(customModel));
                }
              },
            ),
            onDismiss: () => setState(() => _dismissed = true),
          );
        }
        if (state.isPremium) {
          return const _PremiumActiveBadge();
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class ExpiredBanner extends StatefulWidget {
  final VoidCallback onRenewTap;
  final VoidCallback onDismiss;

  const ExpiredBanner({
    super.key,
    required this.onRenewTap,
    required this.onDismiss,
  });

  @override
  State<ExpiredBanner> createState() => _ExpiredBannerState();
}

class _ExpiredBannerState extends State<ExpiredBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -0.3,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 100, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isDark
                        ? [const Color(0xFF2D1B4E), const Color(0xFF1A1A2E)]
                        : [const Color(0xFF6C3CE1), const Color(0xFF4A2C8A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : const Color(0xFF6C3CE1).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.05,
                          child: CustomPaint(painter: _DotPatternPainter()),
                        ),
                      ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            // Icon with animated glow
                            Container(
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
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Text content
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
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Renew button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onRenewTap,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Renew',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF6C3CE1,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Color(0xFF6C3CE1),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Dismiss button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onDismiss,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for dot pattern background
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final dotSpacing = 20.0;
    final dotRadius = 1.5;

    for (double x = 0; x < size.width; x += dotSpacing) {
      for (double y = 0; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative Minimal Design
class MinimalSubscriptionBanner extends StatelessWidget {
  final VoidCallback onRenewTap;
  final VoidCallback onDismiss;

  const MinimalSubscriptionBanner({
    super.key,
    required this.onRenewTap,
    required this.onDismiss,
  });

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
              // Warning icon
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

              // Text
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

              // Buttons
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

// ── Premium active badge ──────────────────────────────────────────────────────

class _PremiumActiveBadge extends StatelessWidget {
  const _PremiumActiveBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.18),
            width: 1,
          ),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    cs.primaryContainer.withValues(alpha: 0.55),
                    cs.tertiaryContainer.withValues(alpha: 0.40),
                  ]
                : [
                    cs.primaryContainer.withValues(alpha: 0.75),
                    cs.tertiaryContainer.withValues(alpha: 0.60),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: cs.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Premium',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'On',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
