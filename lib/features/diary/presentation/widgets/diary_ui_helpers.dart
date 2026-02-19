import 'package:image_picker/image_picker.dart';
import 'package:routine/core/theme/app_colors.dart';
import 'package:routine/core/constants/diary_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DiaryUIHelpers {
  /// Date picker
  static void showDatePicker(
    BuildContext context,
    DateTime initialDate,
    Function(DateTime) onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : Colors.white,
                  initialDateTime: initialDate,
                  mode: CupertinoDatePickerMode.date,
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
                          color: isDark ? Colors.white : AppColors.lightPrimary,
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
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
                      ? AppColors.darkBackground.withValues(alpha: 0.3)
                      : AppColors.lightBackground.withValues(alpha: 0.5),
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
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                        onSelected(
                          isDark ? AppColors.darkSurface : Colors.white,
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: isDark
                                ? AppColors.darkOnBackground.withValues(
                                    alpha: 0.2,
                                  )
                                : Colors.black12,
                          ),
                        ),
                        child: Icon(
                          Icons.clear,
                          color: isDark
                              ? AppColors.darkOnBackground
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

  /// Background image picker
  static void openBgImagePicker(
    BuildContext context, {
    required Function(String assetPath) onPresetSelected,
    required Function(String filePath) onGallerySelected,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.65,
            child: Column(
              children: [
                const SizedBox(height: 12),

                /// Handle bar
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

                /// ----------------------
                /// Gallery Option
                /// ----------------------
                ListTile(
                  trailing: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  titleTextStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold
                  ),
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 5),
                  child: const Divider(
                    thickness: 2,
                    color: Colors.grey,
                  ),
                ),

                /// ----------------------
                /// Preset Grid
                /// ----------------------
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.6,
                        ),
                    itemCount: DiaryItems.bgImages.length + 1,
                    itemBuilder: (gridContext, index) {
                      /// Clear button
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
                                  ? AppColors.darkBackground
                                  : Colors.grey.shade200,
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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

                      final imgPath = DiaryItems.bgImages[index - 1];

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onPresetSelected(imgPath);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                imgPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                              if (isDark)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.25),
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
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                            ? AppColors.darkBackground.withValues(alpha: 0.3)
                            : AppColors.lightBackground.withValues(alpha: 0.5),
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
}
