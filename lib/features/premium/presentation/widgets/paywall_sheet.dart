// lib/features/premium/presentation/widgets/paywall_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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
  final bloc = context.read<PremiumBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _PaywallSheet(
        title: title,
        subtitle: subtitle,
        features: features,
        onSuccess: onSuccess,
      ),
    ),
  ).whenComplete(() {
    // Sheet is fully closed — reset purchasing state if IAP stream never fired.
    // Safe to call even after a successful purchase (bloc ignores if not purchasing).
    if (!bloc.isClosed) {
      bloc.add(const PremiumPurchaseReset());
    }
  });
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
  int _selectedIndex = 1;

  static const _navy = Color(0xFF0D1B3E);

  /// On tablets (>= 600 dp wide) we show the sheet centred with a fixed width.
  static const double _tabletMaxWidth = 560;

  bool get _isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool get _isTablet => MediaQuery.of(context).size.shortestSide >= 600;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom + 16;

    // On tablets / landscape we cap the height so it doesn't fill the screen.
    final maxSheetHeight = _isTablet
        ? mq.size.height * 0.90
        : _isLandscape
        ? mq.size.height * 0.96
        : mq.size.height * 0.92;

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
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final sheet = Container(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          decoration: const BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),

              // ── Scrollable body ──────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: bottomPad),
                  child: _isLandscape && !_isTablet
                      ? _LandscapeBody(
                          state: state,
                          widget: widget,
                          selectedIndex: _selectedIndex,
                          onSelected: (i) => setState(() => _selectedIndex = i),
                        )
                      : _PortraitBody(
                          state: state,
                          widget: widget,
                          selectedIndex: _selectedIndex,
                          onSelected: (i) => setState(() => _selectedIndex = i),
                        ),
                ),
              ),
            ],
          ),
        );

        // Tablet: centre + constrain width, add safe-area padding on sides
        if (_isTablet) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _tabletMaxWidth),
              child: sheet,
            ),
          );
        }

        return sheet;
      },
    );
  }
}

// ── Portrait layout (phone portrait + tablet) ─────────────────────────────────

class _PortraitBody extends StatelessWidget {
  final PremiumState state;
  final _PaywallSheet widget;
  final int selectedIndex;
  final ValueChanged<int> onSelected;


  const _PortraitBody({
    required this.state,
    required this.widget,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroHeader(title: widget.title, subtitle: widget.subtitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: widget.features
                .map((f) => _FeatureRow(label: f))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        _PlanArea(
          state: state,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SubscribeButton(
            state: state,
            selectedPlan:
                state.hasPlans && selectedIndex < state.subscriptionPlans.length
                ? state.subscriptionPlans[selectedIndex]
                : null,
          ),
        ),
        _Footer(isPurchasing: state.isPurchasing),
      ],
    );
  }
}

// ── Landscape layout (phone landscape only) ───────────────────────────────────
//
// Two-column: hero/features on left, plans + CTA on right.

class _LandscapeBody extends StatelessWidget {
  final PremiumState state;
  final _PaywallSheet widget;
  final int selectedIndex;
  final ValueChanged<int> onSelected;


  const _LandscapeBody({
    required this.state,
    required this.widget,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LEFT: title + features ───────────────────────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompactHeroHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                ),
                const SizedBox(height: 12),
                ...widget.features.map((f) => _FeatureRow(label: f)),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ── RIGHT: plans + CTA + footer ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _PlanArea(
                  state: state,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                ),
                const SizedBox(height: 16),
                _SubscribeButton(
                  state: state,
                  selectedPlan:
                      state.hasPlans &&
                          selectedIndex < state.subscriptionPlans.length
                      ? state.subscriptionPlans[selectedIndex]
                      : null,
                ),
                _Footer(isPurchasing: state.isPurchasing),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared plan area (loading / unavailable / selector) ───────────────────────

class _PlanArea extends StatelessWidget {
  final PremiumState state;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _gold = Color(0xFFFFC94A);

  const _PlanArea({
    required this.state,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: state.isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: _gold),
            )
          : !state.hasPlans
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Plans unavailable. Please check your connection.',
                style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          : _PlanSelector(
              plans: state.subscriptionPlans,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
    );
  }
}

// ── Footer (restore + legal) ──────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isPurchasing;

  const _Footer({required this.isPurchasing});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PremiumBloc>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: isPurchasing
              ? () => !bloc.isClosed
                    ? bloc.add(const PremiumPurchaseReset())
                    : null
              : () => bloc.add(const PremiumRestoreRequested()),
          child: const Text(
            'Restore Purchase',
            style: TextStyle(color: Color(0xFFABBAD9), fontSize: 13),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Renews automatically · Cancel anytime',
            style: TextStyle(color: Color(0xFF5A6E9A), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ── Hero Header (portrait / tablet) ──────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  static const _gold = Color(0xFFFFC94A);
  static const _textSecondary = Color(0xFFABBAD9);

  const _HeroHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2F6B), Color(0xFF0D1B3E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFDE7A), Color(0xFFE6A800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF7A4800),
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Compact Hero Header (landscape phone — left column) ───────────────────────

class _CompactHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  static const _gold = Color(0xFFFFC94A);
  static const _textSecondary = Color(0xFFABBAD9);

  const _CompactHeroHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFDE7A), Color(0xFFE6A800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFF7A4800),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Feature Row ───────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String label;

  static const _gold = Color(0xFFFFC94A);
  static const _cardBg = Color(0xFF1E2D5A);

  const _FeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _gold, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan Selector ─────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final List<ProductDetails> plans;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _gold = Color(0xFFFFC94A);
  static const _cardBg = Color(0xFF1E2D5A);

  const _PlanSelector({
    required this.plans,
    required this.selectedIndex,
    required this.onSelected,
  });

  String _label(ProductDetails p) {
    // On Android, find the base plan whose price matches this product variant.
    final id = (_matchedBasePlanId(p) ?? p.id).toLowerCase();

    if (id.contains('3month') ||
        id.contains('3-month') ||
        id.contains('quarter') ||
        id.contains('quarterly')) {
      return '3 Months';
    }
    if (id.contains('year') || id.contains('yearly') || id.contains('annual')) {
      return 'Yearly';
    }
    if (id.contains('lifetime') ||
        id.contains('permanent') ||
        id.contains('forever')) {
      return 'Permanent';
    }
    if (id.contains('month') || id.contains('monthly')) {
      return 'Monthly';
    }

    // Fallback: price-based detection (unchanged)
    final raw = p.price.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(raw) ?? 0;
    if (amount == 0) return p.title;

    final prices =
        plans
            .map(
              (pl) =>
                  double.tryParse(pl.price.replaceAll(RegExp(r'[^\d.]'), '')) ??
                  0,
            )
            .where((v) => v > 0)
            .toList()
          ..sort();

    if (prices.length < 2) return p.title;
    final min = prices.first;
    final max = prices.last;
    final third = (max - min) / 3;

    if (amount <= min + third) return 'Monthly';
    if (amount >= max - third) return 'Yearly';
    return '3 Months';
  }

  String? _matchedBasePlanId(ProductDetails details) {
    if (details is! GooglePlayProductDetails) return null;

    final offers = details.productDetails.subscriptionOfferDetails ?? [];

    // Find the offer whose pricing phase matches this product's rawPrice.
    for (final offer in offers) {
      final phases = offer.pricingPhases;
      for (final phase in phases) {
        // pricingPhaseList prices are in micros (e.g. 100000000 = ₹100)
        final offerPrice = phase.priceAmountMicros / 1000000;
        if ((offerPrice - details.rawPrice).abs() < 0.5) {
          return offer.basePlanId;
        }
      }
    }

    return null;
  }

  bool _isBestValue(ProductDetails p) {
    final id = p.id.toLowerCase();
    return id.contains('yearly') || id.contains('annual');
  }

  bool _isPermanent(ProductDetails p) {
    final id = p.id.toLowerCase();
    return id.contains('lifetime') ||
        id.contains('permanent') ||
        id.contains('forever');
  }

  String? _subLabel(ProductDetails p) {
    if (_isPermanent(p)) return 'Pay once, unlock forever';

    final raw = p.price.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(raw) ?? 0;
    if (amount == 0) return null;

    final currencySymbol = p.price.replaceAll(RegExp(r'[\d.,\s]'), '').trim();

    final label = _label(p);
    if (label == 'Monthly') {
      return '$currencySymbol${(amount / 4).toStringAsFixed(2)}/wk';
    }
    if (label == 'Yearly') {
      return '$currencySymbol${(amount / 52).toStringAsFixed(2)}/wk';
    }
    if (label == '3 Months') {
      return '$currencySymbol${(amount / 13).toStringAsFixed(2)}/wk';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(plans.length, (i) {
        final plan = plans[i];
        final isSelected = i == selectedIndex;
        final bestValue = _isBestValue(plan);
        final permanent = _isPermanent(plan);
        final subLabel = _subLabel(plan);

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed-height badge row
                SizedBox(
                  height: 26,
                  child: bestValue
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFDE7A), Color(0xFFE6A800)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              '★ Best Value',
                              style: TextStyle(
                                color: Color(0xFF7A4800),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 4),

                // Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: isSelected ? _gold.withValues(alpha: 0.10) : _cardBg,
                    border: Border.all(
                      color: isSelected
                          ? _gold
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _label(plan),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected ? _gold : const Color(0xFFABBAD9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        plan.price,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF7A8EBB),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      _StrikethroughPrice(plan: plan),
                      const SizedBox(height: 10),
                      if (subLabel != null)
                        _SubLabelPill(
                          label: subLabel,
                          isSelected: isSelected,
                          isPermanent: permanent,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: isSelected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Strikethrough Price ───────────────────────────────────────────────────────

class _StrikethroughPrice extends StatelessWidget {
  final ProductDetails plan;

  const _StrikethroughPrice({required this.plan});

  String? _originalPrice() {
    final desc = plan.description;
    final match = RegExp(r'was:([^\s]+)').firstMatch(desc);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final original = _originalPrice();
    if (original == null) return const SizedBox(height: 14);

    return Text(
      original,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF4E5F88),
        decoration: TextDecoration.lineThrough,
        decorationColor: Color(0xFF4E5F88),
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Sub-label pill ────────────────────────────────────────────────────────────

class _SubLabelPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isPermanent;

  static const _gold = Color(0xFFFFC94A);

  const _SubLabelPill({
    required this.label,
    required this.isSelected,
    required this.isPermanent,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final double fontSize;

    if (isPermanent) {
      bg = Colors.white.withValues(alpha: 0.06);
      fg = const Color(0xFF6B7FAB);
      fontSize = 9;
    } else if (isSelected) {
      bg = _gold.withValues(alpha: 0.14);
      fg = _gold;
      fontSize = 10;
    } else {
      bg = Colors.white.withValues(alpha: 0.04);
      fg = const Color(0xFF4E5F88);
      fontSize = 10;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Subscribe Button ──────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  final PremiumState state;
  final ProductDetails? selectedPlan;

  const _SubscribeButton({required this.state, required this.selectedPlan});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: state.isPurchasing || selectedPlan == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFFDE7A), Color(0xFFE6A800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: state.isPurchasing || selectedPlan == null
              ? const Color(0xFF2A3A6A)
              : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: state.isPurchasing || selectedPlan == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFE6A800).withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: state.isPurchasing || selectedPlan == null
              ? null
              : () => context.read<PremiumBloc>().add(
                  PremiumPurchaseRequested(selectedPlan!),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: state.isPurchasing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF7A4800),
                  ),
                )
              : Text(
                  selectedPlan != null
                      ? 'Subscribe for ${selectedPlan!.price}'
                      : 'Subscribe',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A3000),
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
