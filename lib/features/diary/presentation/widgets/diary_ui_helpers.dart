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
    bool allowFutureDates = false,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final DateTime today = DateTime.now();
    final DateTime minDate = DateTime(2000);
    final DateTime maxDate = allowFutureDates ? DateTime(2100) : today;

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
                  maximumDate: maxDate,
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

  /// Emoji picker (unchanged)
  static void openEmojiPicker(
    BuildContext context,
    Function(String) onSelected,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
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
                        color: isDark
                            ? theme.colorScheme.surface.withValues(alpha: 0.5)
                            : theme.colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
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

  /// Color picker (unchanged)
  static void openColorPicker(
    BuildContext context,
    Function(Color) onSelected,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = isDark ? AppColors.darkColors : AppColors.lightColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
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
                    return GestureDetector(
                      onTap: () {
                        onSelected(theme.colorScheme.surface);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surface
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: isDark
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.2,
                                  )
                                : Colors.black12,
                          ),
                        ),
                        child: Icon(
                          Icons.clear,
                          color: isDark
                              ? theme.colorScheme.onSurface
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

  /// Background image picker (unchanged)
  static void openBgImagePicker(
    BuildContext context, {
    required Function(String assetPath) onPresetSelected,
    required Function(String filePath) onGallerySelected,
    required VoidCallback onClear,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bloc = context.read<DiaryEntryBloc>();

    bloc.add(LoadBackgrounds());

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: Border(),

      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.5,

              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  children: [
                    Text(
                      'Choose Background',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        try {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null && context.mounted) {
                            onGallerySelected(image.path);
                          }
                        } catch (e) {
                          debugPrint('Gallery pick failed: $e');
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          color: theme.colorScheme.primary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            spacing: 10,
                            children: [
                              Icon(
                                CupertinoIcons.photo,
                                color: theme.colorScheme.onPrimary,
                              ),
                              Expanded(
                                child: Text(
                                  'Choose from gallery',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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
                                    onPressed: () =>
                                        bloc.add(LoadBackgrounds()),
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
                                  crossAxisCount: 5,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.6,
                                ),
                            itemCount: state.availableBackgrounds.length + 1,
                            itemBuilder: (gridContext, index) {
                              if (index == 0) {
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
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
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
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholder: (_, __) =>
                                        Container(color: Colors.grey.shade200),
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
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
          ),
        );
      },
    );
  }

  static void openStickerPicker(
    BuildContext context, {
    required Function(String stickerUrl, double x, double y) onStickerSelected,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    final theme = Theme.of(context);
    final bloc = context.read<DiaryEntryBloc>();

    if (bloc.state.stickersByCategory.isEmpty) {
      bloc.add(LoadStickers());
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: Border(),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.5,

              child: BlocBuilder<DiaryEntryBloc, DiaryEntryState>(
                buildWhen: (prev, current) =>
                    prev.stickersByCategory != current.stickersByCategory ||
                    prev.isLoadingStickers != current.isLoadingStickers ||
                    prev.stickersError != current.stickersError,
                builder: (context, state) {
                  if (state.isLoadingStickers) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.stickersError != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Please check your internet connection, or please restart the app',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => bloc.add(LoadStickers()),
                            child: const Text("Try again"),
                          ),
                        ],
                      ),
                    );
                  }

                  final categories = state.stickersByCategory.keys.toList();

                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No stickers yet",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DefaultTabController(
                    length: categories.length,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: TabBar(
                            padding: EdgeInsets.all(5),
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: categories.map((cat) {
                              return Tab(text: cat);
                            }).toList(),
                            labelStyle: theme.textTheme.titleSmall!.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            indicatorSize: TabBarIndicatorSize.label,
                            indicatorColor: theme.colorScheme.primary,
                            unselectedLabelColor: Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: categories.map((category) {
                              final stickerUrls =
                                  state.stickersByCategory[category] ?? [];

                              if (stickerUrls.isEmpty) {
                                return Center(
                                  child: Text(
                                    "Nothing in this category",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: stickerUrls.length,
                                itemBuilder: (ctx, index) {
                                  final url = stickerUrls[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      onStickerSelected(url, 0.5, 0.5);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        fadeInDuration: Duration.zero,
                                        fadeOutDuration: Duration.zero,
                                        placeholder: (_, __) =>
                                            const SizedBox.shrink(),
                                        imageUrl: url,
                                        fit: BoxFit.contain,

                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
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
