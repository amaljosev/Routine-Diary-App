import 'package:flutter/material.dart';

const List<Map<String, String>> availableFonts = [
  {'display': 'Quicksand', 'family': 'Quicksand'},
  {'display': 'Caveat', 'family': 'Caveat'},
  {'display': 'Cormorant Garamond', 'family': 'CormorantGaramond'},
  {'display': 'Dancing Script', 'family': 'DancingScript'},
  {'display': 'Playfair Display', 'family': 'PlayfairDisplay'},
  {'display': 'AmaticSC', 'family': 'AmaticSC'},
  {'display': 'GoldmanGoldman', 'family': 'Goldman'},
  {'display': 'ShadowsIntoLight', 'family': 'ShadowsIntoLight'},
];

/// Bottom sheet that lets the user pick a font family for the diary entry.
class FontPickerSheet extends StatelessWidget {
  final String currentFont;
  final ValueChanged<String> onFontSelected;

  const FontPickerSheet({
    super.key,
    required this.currentFont,
    required this.onFontSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Font',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableFonts.length,
                itemBuilder: (context, index) {
                  final font = availableFonts[index];
                  final isSelected = font['family'] == currentFont;
                  return GestureDetector(
                    onTap: () => onFontSelected(font['family']!),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              font['display']!,
                              style: theme.textTheme.bodyMedium!
                                  .copyWith(fontFamily: font['family']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}