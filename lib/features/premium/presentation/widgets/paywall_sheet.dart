// lib/features/premium/presentation/widgets/paywall_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../bloc/premium_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — all pink-theme colors live here so they're easy to update.
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  // Sheet background gradient stops
  static const bgTop = Color(0xFF2A0618);
  static const bgBottom = Color(0xFF130208);

  // Radial glow behind the icon
  static const glowColor = Color(0xFFD4537E);

  // Icon circle gradient
  static const iconGradTop = Color(0xFFF9A8D4); // pink-300
  static const iconGradBottom = Color(0xFFE11D74); // pink-600

  // Primary accent (borders, highlights, badge gradient start)
  static const pink = Color(0xFFE11D74);
  static const pink2 = Color(0xFFF472B6); // lighter end

  // Text colors on dark sheet
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0x99FFFFFF); // 60 % white
  static const textMuted = Color(0x4DFFFFFF); // 30 % white

  // Feature row icon backgrounds
  static const featPinkBg = Color(0x26F472B6); // pink  / 15 %
  static const featBlueBg = Color(0x263B82F6); // blue-500 / 15 %

  // Plan card colors
  static const cardBg = Color(0x0DFFFFFF); //  5 % white fill
  static const cardBorder = Color(0x14FFFFFF); //  8 % white border
  static const cardSelBg = Color(0x1AE11D74); // pink / 10 %

  // Subscribe button gradient
  static const btnTop = Color(0xFFF472B6);
  static const btnBottom = Color(0xFFBE185D);
  static const btnShadow = Color(0x66E11D74); // 40 % pink

  // "Best value" badge gradient
  static const badgeStart = Color(0xFFF9A8D4);
  static const badgeEnd = Color(0xFFE11D74);

  // Footer / restore
  static const restoreText = Color(0x66FFFFFF);
  static const legalText = Color(0x33FFFFFF);
  static const legalDot = Color(0xFFE11D74);

  // Plans unavailable error
  static const errorText = Color(0xFFFF6B8A);

  // Section label
  static const sectionLabel = Color(0x4DFFFFFF); // 30 % white
}

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point (API unchanged)
// ─────────────────────────────────────────────────────────────────────────────

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
    'Google Drive backup & restore',
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
    if (!bloc.isClosed) {
      bloc.add(const PremiumPurchaseReset());
    }
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell widget — handles responsive layout + BlocConsumer
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

  static const double _tabletMaxWidth = 560;

  bool get _isLandscape =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  bool get _isTablet => MediaQuery.of(context).size.shortestSide >= 600;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom + 16;

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
            gradient: LinearGradient(
              colors: [_T.bgTop, _T.bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.70),
                            size: 18,
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 35),
                    ],
                  ),
                ),
              ),

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
// ─────────────────────────────────────────────────────────────────────────────
// Portrait layout
// ─────────────────────────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('What you get'),
              ...widget.features.map((f) => _FeatureRow(label: f)),
              _sectionLabel('Choose your plan'),
            ],
          ),
        ),
        _PlanArea(
          state: state,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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

// ─────────────────────────────────────────────────────────────────────────────
// Landscape layout — two column
// ─────────────────────────────────────────────────────────────────────────────

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
          // LEFT — icon + title + features
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
                _sectionLabel('What you get'),
                ...widget.features.map((f) => _FeatureRow(label: f)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // RIGHT — plans + CTA + footer
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const SizedBox(height: 8),
                _sectionLabel('Choose your plan'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Section label helper (shared between portrait & landscape)
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionLabel(String text) => Padding(
  padding: const EdgeInsets.only(top: 18, bottom: 8),
  child: Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: _T.sectionLabel,
    ),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Hero header — portrait / tablet
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Radial glow
        Positioned(
          top: 0,
          child: Container(
            width: 220,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _T.glowColor.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              // Crown icon circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_T.iconGradTop, _T.iconGradBottom],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _T.pink.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  color: _T.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _T.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact hero header — landscape phone (left column)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;

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
              colors: [_T.iconGradTop, _T.iconGradBottom],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _T.pink.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 24,
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
                  color: _T.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _T.textSecondary,
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

// ─────────────────────────────────────────────────────────────────────────────
// Feature row
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String label;

  const _FeatureRow({required this.label});

  // Detect Google Drive / cloud backup rows to give them a distinct blue icon.
  static bool _isDriveFeature(String label) {
    final l = label.toLowerCase();
    return l.contains('google drive') ||
        l.contains('backup') ||
        l.contains('restore') ||
        l.contains('cloud');
  }

  @override
  Widget build(BuildContext context) {
    final isDrive = _isDriveFeature(label);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _T.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDrive
              ? const Color(0x263B82F6) // blue tint border for drive row
              : _T.pink.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDrive ? _T.featBlueBg : _T.featPinkBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDrive ? Icons.cloud_done_outlined : Icons.check_rounded,
              color: isDrive ? const Color(0xFF60A5FA) : _T.pink2,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan area — handles loading / unavailable / selector states
// ─────────────────────────────────────────────────────────────────────────────

class _PlanArea extends StatelessWidget {
  final PremiumState state;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PlanArea({
    required this.state,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: state.isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: _T.pink),
            )
          : !state.hasPlans
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Plans unavailable. Please check your connection.',
                style: TextStyle(color: _T.errorText, fontSize: 13),
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

// ─────────────────────────────────────────────────────────────────────────────
// Plan selector — row of tappable plan cards
// ─────────────────────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final List<ProductDetails> plans;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PlanSelector({
    required this.plans,
    required this.selectedIndex,
    required this.onSelected,
  });

  // ── Label helpers (unchanged logic from original) ──────────────────────────

  String _label(ProductDetails p) {
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
      return 'Lifetime';
    }
    if (id.contains('month') || id.contains('monthly')) return 'Monthly';

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
    for (final offer in offers) {
      for (final phase in offer.pricingPhases) {
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
    if (_isPermanent(p)) return 'Pay once, keep forever';

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
                // Fixed-height badge row so cards stay aligned
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
                                colors: [_T.badgeStart, _T.badgeEnd],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _T.pink.withValues(alpha: 0.40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              '★ Best Value',
                              style: TextStyle(
                                color: Colors.white,
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

                // Plan card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
                  decoration: BoxDecoration(
                    color: isSelected ? _T.cardSelBg : _T.cardBg,
                    border: Border.all(
                      color: isSelected ? _T.pink : _T.cardBorder,
                      width: isSelected ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _T.pink.withValues(alpha: 0.22),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Period label
                      Text(
                        _label(plan),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: isSelected ? _T.pink2 : _T.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Price
                      Text(
                        plan.price,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isSelected ? _T.textPrimary : _T.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),

                      // Strikethrough (if present in description)
                      _StrikethroughPrice(plan: plan),
                      const SizedBox(height: 8),

                      // Sub-label pill
                      if (subLabel != null)
                        _SubLabelPill(
                          label: subLabel,
                          isSelected: isSelected,
                          isPermanent: permanent,
                        ),
                    ],
                  ),
                ),

                // Selection indicator bar
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: isSelected ? 24 : 0,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [_T.pink2, _T.pink])
                        : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Strikethrough original price (parsed from product description)
// ─────────────────────────────────────────────────────────────────────────────

class _StrikethroughPrice extends StatelessWidget {
  final ProductDetails plan;

  const _StrikethroughPrice({required this.plan});

  String? _originalPrice() {
    final match = RegExp(r'was:([^\s]+)').firstMatch(plan.description);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final original = _originalPrice();
    if (original == null) return const SizedBox(height: 14);

    return Text(
      original,
      style: TextStyle(
        fontSize: 11,
        color: _T.textMuted,
        decoration: TextDecoration.lineThrough,
        decorationColor: _T.textMuted,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-label pill (weekly breakdown / "Pay once" etc.)
// ─────────────────────────────────────────────────────────────────────────────

class _SubLabelPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isPermanent;

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
      fg = _T.textMuted;
      fontSize = 9;
    } else if (isSelected) {
      bg = _T.pink.withValues(alpha: 0.18);
      fg = _T.pink2;
      fontSize = 10;
    } else {
      bg = Colors.white.withValues(alpha: 0.04);
      fg = _T.textMuted;
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

// ─────────────────────────────────────────────────────────────────────────────
// Subscribe CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  final PremiumState state;
  final ProductDetails? selectedPlan;

  const _SubscribeButton({required this.state, required this.selectedPlan});

  @override
  Widget build(BuildContext context) {
    final active = !state.isPurchasing && selectedPlan != null;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [_T.btnTop, _T.btnBottom],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(27),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _T.btnShadow,
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: active
              ? () => context.read<PremiumBloc>().add(
                  PremiumPurchaseRequested(selectedPlan!),
                )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
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
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer — restore purchase + legal note
// ─────────────────────────────────────────────────────────────────────────────

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
              ? () {
                  if (!bloc.isClosed) bloc.add(const PremiumPurchaseReset());
                }
              : () => bloc.add(const PremiumRestoreRequested()),
          child: const Text(
            'Restore purchase',
            style: TextStyle(color: _T.restoreText, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: _T.legalDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Renews automatically · Cancel anytime',
                style: TextStyle(color: _T.legalText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
