// lib/features/premium/presentation/widgets/subscription_banner_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/premium/presentation/bloc/premium_bloc.dart';

/// A banner that sits at the top of DiaryScreen to show subscription status.
///
/// Shows nothing when the user is premium and in good standing.
/// Shows an "expired" warning when the subscription has lapsed.
/// Shows a subtle "premium active" chip when the user is premium.
///
/// Usage — add inside the scrollable content's SliverList, just below
/// the SliverAppBar, before the "Recent Entries" header:
///
/// ```dart
/// SliverToBoxAdapter(
///   child: const SubscriptionStatusBanner(),
/// ),
/// ```
class SubscriptionStatusBanner extends StatelessWidget {
  const SubscriptionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PremiumBloc, PremiumState>(
      // Only rebuild when premium/expiry status changes — not on every state.
      buildWhen: (prev, curr) =>
          prev.isPremium != curr.isPremium ||
          prev.showExpiredBanner != curr.showExpiredBanner ||
          prev.subscriptionExpired != curr.subscriptionExpired,
      listenWhen: (prev, curr) =>
          !prev.showExpiredBanner && curr.showExpiredBanner,
      listener: (context, state) {
        // Once shown, mark the banner as seen so it won't re-appear if the
        // widget rebuilds (e.g. on navigation return).
        Future.microtask(
          () => context.read<PremiumBloc>().add(
            const PremiumExpiredBannerShown(),
          ),
        );
      },
      builder: (context, state) {
        // ── 1. Subscription expired ──────────────────────────────────────
        if (state.subscriptionExpired || state.showExpiredBanner) {
          return _ExpiredBanner(onRenewTap: () {});
        }

        // ── 2. Active premium ────────────────────────────────────────────
        if (state.isPremium) {
          return const _PremiumActiveBadge();
        }

        // ── 3. Free user — show nothing ──────────────────────────────────
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Expired banner ────────────────────────────────────────────────────────────

class _ExpiredBanner extends StatelessWidget {
  final VoidCallback onRenewTap;
  const _ExpiredBanner({required this.onRenewTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.error.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Expired',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your premium features have been paused. Renew to restore custom themes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer.withValues(
                          alpha: 0.80,
                        ),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Renew CTA
              TextButton(
                onPressed: onRenewTap,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  backgroundColor: colorScheme.error.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Renew',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // Subtle gradient pill — uses primary/tertiary so it adapts to any theme.
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Premium Active',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.greenAccent.shade400,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.shade400.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Active',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
