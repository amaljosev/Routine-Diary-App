import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:routine/core/theme/app_colors.dart';
import 'package:routine/core/constants/diary_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:routine/features/diary/presentation/blocs/diary_entry/diary_entry_bloc.dart';

class DiaryUIHelpers {
  /// Date picker
  static void showDatePicker(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime) onChanged, {
    bool allowFutureDates =
        false, // Add this parameter to control future date access
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Set minimum and maximum dates
    final DateTime today = DateTime.now();
    final DateTime minDate = DateTime(2000); // Adjust as needed
    final DateTime maxDate = allowFutureDates
        ? DateTime(
            2100,
          ) // Allow dates up to year 2100 if future dates are allowed
        : today; // Only allow up to today if future dates are not allowed

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: isDark ? theme.colorScheme.surface : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  backgroundColor: isDark
                      ? theme.colorScheme.surface
                      : Colors.white,
                  initialDateTime: initialDate,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: minDate,
                  maximumDate: maxDate, // This controls future date access
                  onDateTimeChanged: onChanged,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Emoji picker
  static void openEmojiPicker(
    BuildContext context,
    Function(String) onSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface, 
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        
      ),
      builder: (_) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'What is your mood',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: DiaryItems.moods.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final emoji = DiaryItems.moods[index];
                  return GestureDetector(
                    onTap: () {
                      onSelected(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        // Use theme surface color with opacity
                        color: isDark
                            ? theme.colorScheme.surface.withValues(
                                alpha: 0.5,
                              ) // Updated
                            : theme.colorScheme.surface.withValues(
                                alpha: 0.5,
                              ), // Updated
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Color picker
  static void openColorPicker(
    BuildContext context,
    Function(Color) onSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.darkColors : AppColors.lightColors;

    showModalBottomSheet(
      context: context,
      // Use theme surface color
      backgroundColor: theme.colorScheme.surface, // Updated
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose Background Color',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: colors.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    // Clear selection item
                    return GestureDetector(
                      onTap: () {
                        // Use theme surface color for clear
                        onSelected(theme.colorScheme.surface); // Updated
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme
                                    .colorScheme
                                    .surface // Updated
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: isDark
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  ) // Updated
                                : Colors.black12,
                          ),
                        ),
                        child: Icon(
                          Icons.clear,
                          color: isDark
                              ? theme
                                    .colorScheme
                                    .onSurface // Updated
                              : Colors.black54,
                        ),
                      ),
                    );
                  }

                  final colorIndex = index - 1;
                  final color = colors[colorIndex]['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      onSelected(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black12,
                        ),
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

  static void openBgImagePicker(
    BuildContext context, {
    required Function(String assetPath) onPresetSelected, // now receives URL
    required Function(String filePath) onGallerySelected,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bloc = context.read<DiaryEntryBloc>();

    // Load backgrounds when bottom sheet is opened
    bloc.add(LoadBackgrounds());

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.65,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Background',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gallery option
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from Gallery'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (image != null && context.mounted) {
                          onGallerySelected(image.path);
                        }
                      } catch (e) {
                        debugPrint('Gallery pick failed: $e');
                      }
                    },
                  ),

                  const Divider(thickness: 2, indent: 16, endIndent: 16),

                  // Presets from Supabase
                  Expanded(
                    child: BlocBuilder<DiaryEntryBloc, DiaryEntryState>(
                      buildWhen: (prev, current) =>
                          prev.availableBackgrounds !=
                              current.availableBackgrounds ||
                          prev.isLoadingBackgrounds !=
                              current.isLoadingBackgrounds ||
                          prev.backgroundsError != current.backgroundsError,
                      builder: (context, state) {
                        if (state.isLoadingBackgrounds) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.backgroundsError != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load: Please check your internet connection',
                                ),
                                TextButton(
                                  onPressed: () => bloc.add(LoadBackgrounds()),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (state.availableBackgrounds.isEmpty) {
                          return const Center(
                            child: Text('No background images found'),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.6,
                              ),
                          itemCount:
                              state.availableBackgrounds.length +
                              1, // +1 for clear button
                          itemBuilder: (gridContext, index) {
                            if (index == 0) {
                              // Clear button
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  onClear();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isDark
                                        ? theme.colorScheme.surface
                                        : Colors.grey.shade200,
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.clear),
                                        SizedBox(height: 6),
                                        Text("Clear"),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final imageUrl =
                                state.availableBackgrounds[index - 1];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(sheetContext);
                                onPresetSelected(imageUrl);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sticker picker
  static void openStickerPicker(
    BuildContext context,
    Function(String) onSelected,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      // Use theme surface color
      backgroundColor: theme.colorScheme.surface, // Updated
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose Sticker',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: DiaryItems.emojis.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, index) {
                  final sticker = DiaryItems.emojis[index];
                  return GestureDetector(
                    onTap: () {
                      onSelected(sticker);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surface.withValues(
                                alpha: 0.5,
                              ) // Updated
                            : theme.colorScheme.surface.withValues(
                                alpha: 0.5,
                              ), // Updated
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          sticker,
                          style: const TextStyle(fontSize: 32),
                        ),
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

  /// Insert bullet into a TextEditingController
  static void insertBullet(TextEditingController controller) {
    final text = controller.text;
    controller.text = '$text\n• ';
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  static Color generateDarkColorFromText(String text) {
    final hash = text.hashCode;
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.3).toColor();
  }

  static Color darken(Color color, {double amount = 0.6}) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);

    final double newLightness = (hsl.lightness * (1 - amount)).clamp(0.0, 1.0);

    return hsl.withLightness(newLightness).toColor();
  }
}
