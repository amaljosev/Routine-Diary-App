import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../bloc/premium_bloc.dart';

Future<void> showPaywallSheet(
  BuildContext context, {
  required VoidCallback onSuccess,
  String title = 'Unlock Premium',
  String subtitle = 'Subscribe and unlock all premium features.',
  List<String> features = const [
    'Custom header image from gallery',
    'Choose from built-in asset headers',
    'Pick any primary & secondary color',
    'Unlimited theme combinations',
  ],
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<PremiumBloc>(),
      child: _PaywallSheet(
        title: title,
        subtitle: subtitle,
        features: features,
        onSuccess: onSuccess,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaywallSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> features;
  final VoidCallback onSuccess;

  const _PaywallSheet({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.onSuccess,
  });

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  // Index of the plan the user has selected (default: middle plan = index 1)
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocConsumer<PremiumBloc, PremiumState>(
      listenWhen: (prev, curr) =>
          prev.isPremium != curr.isPremium ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.isPremium) {
          Navigator.of(context).pop();
          widget.onSuccess();
          return;
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            const SizedBox(height: 24),
            _CrownIcon(),
            const SizedBox(height: 16),
            // Title
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Feature list
            ...widget.features.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Plan selector ────────────────────────────────────────────────
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              )
            else if (!state.hasPlans)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Plans unavailable. Please check your connection.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              _PlanSelector(
                plans: state.subscriptionPlans,
                selectedIndex: _selectedIndex,
                onSelected: (i) => setState(() => _selectedIndex = i),
              ),

            const SizedBox(height: 20),

            // ── Subscribe button ─────────────────────────────────────────────
            _SubscribeButton(
              state: state,
              selectedPlan: state.hasPlans &&
                      _selectedIndex < state.subscriptionPlans.length
                  ? state.subscriptionPlans[_selectedIndex]
                  : null,
            ),
            const SizedBox(height: 12),
            _RestoreButton(state: state),
            const SizedBox(height: 4),
            // Legal note
            Text(
              'Subscription renews automatically. Cancel anytime.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan Selector ─────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final List<ProductDetails> plans;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PlanSelector({
    required this.plans,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Label shown above the plan card — derived from product ID.
  String _label(ProductDetails p) {
    final id = p.id.toLowerCase();
    if (id.contains('yearly') || id.contains('annual')) return 'Yearly';
    if (id.contains('3month') || id.contains('quarter')) return '3 Months';
    if (id.contains('monthly')) return 'Monthly';
    return p.title; // fallback to store title
  }

  /// Badge shown on the best-value plan.
  bool _isBestValue(ProductDetails p) {
    final id = p.id.toLowerCase();
    return id.contains('yearly') || id.contains('annual');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      children: List.generate(plans.length, (i) {
        final plan = plans[i];
        final isSelected = i == selectedIndex;
        final bestValue = _isBestValue(plan);

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                border: Border.all(
                  color: isSelected ? primary : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Best value badge
                  if (bestValue)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Best Value',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 22), // keep heights equal
                  // Plan duration label
                  Text(
                    _label(plan),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primary : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Price from Play Store
                  Text(
                    plan.price,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Subscribe Button ──────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  final PremiumState state;
  final ProductDetails? selectedPlan;

  const _SubscribeButton({required this.state, required this.selectedPlan});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: state.isPurchasing || selectedPlan == null
              ? null
              : () => context
                  .read<PremiumBloc>()
                  .add(PremiumPurchaseRequested(selectedPlan!)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade600,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                Colors.amber.shade600.withValues(alpha: 0.4),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
          ),
          child: state.isPurchasing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  selectedPlan != null
                      ? 'Subscribe for ${selectedPlan!.price}'
                      : 'Subscribe',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      );
}

// ── Restore Button ────────────────────────────────────────────────────────────

class _RestoreButton extends StatelessWidget {
  final PremiumState state;
  const _RestoreButton({required this.state});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: state.isPurchasing
            ? null
            : () => context
                .read<PremiumBloc>()
                .add(const PremiumRestoreRequested()),
        child: Text(
          'Restore Purchase',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
            fontSize: 13,
          ),
        ),
      );
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _CrownIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade300, Colors.orange.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 36,
        ),
      );
}