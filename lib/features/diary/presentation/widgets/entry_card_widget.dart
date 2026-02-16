import 'package:consist/core/theme/app_colors.dart';
import 'package:consist/core/utils/converters.dart';
import 'package:consist/features/diary/data/models/diary_entry_model.dart';
import 'package:consist/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:consist/features/diary/presentation/pages/preview/diary_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntryModel entry;

  const DiaryEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Generate a color based on the entry's mood or content
    final color = _generateColorFromText(entry.mood + entry.title);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkSurface.withValues(alpha: 0.6)
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiaryPreviewScreen(entryId: entry.id),
              ),
            );
            if (result == true && context.mounted) {
              context.read<DiaryBloc>().add(LoadDiaryEntries());
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date indicator
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withValues(alpha: 0.3)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getDay(entry.date),
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : color,
                        ),
                      ),
                      Text(
                        _getMonth(entry.date),
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.8)
                              : color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Mood emoji
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              entry.mood,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Title
                          Expanded(
                            child: Text(
                              entry.title.isEmpty ? "Untitled" : entry.title,
                              style: theme.textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Preview text
                      if (entry.preview.isNotEmpty)
                        Text(
                          entry.preview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        )
                      else
                        Text(
                          "No content yet...",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Time and tags
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTime(entry.date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),

                          // You can add tags here later
                          // const Spacer(),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          //   decoration: BoxDecoration(
                          //     color: isDark 
                          //         ? AppColors.darkBackground.withValues(alpha: 0.5)
                          //         : Colors.grey[100],
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   child: Text(
                          //     "Personal",
                          //     style: theme.textTheme.labelSmall?.copyWith(
                          //       color: theme.colorScheme.primary,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDay(String date) {
    final DateTime newDate =
        AppConverters.stringToDateTime(date) ?? DateTime.now();
    return newDate.day.toString();
  }

  String _getMonth(String date) {
    final DateTime newDate =
        AppConverters.stringToDateTime(date) ?? DateTime.now();
    // Return month in format like "Jan", "Feb", etc.
    switch (newDate.month) {
      case 1: return 'JAN';
      case 2: return 'FEB';
      case 3: return 'MAR';
      case 4: return 'APR';
      case 5: return 'MAY';
      case 6: return 'JUN';
      case 7: return 'JUL';
      case 8: return 'AUG';
      case 9: return 'SEP';
      case 10: return 'OCT';
      case 11: return 'NOV';
      case 12: return 'DEC';
      default: return newDate.month.toString().padLeft(2, '0');
    }
  }

  String _getTime(String date) {
    final DateTime newDate =
        AppConverters.stringToDateTime(date) ?? DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(newDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${newDate.day}/${newDate.month}/${newDate.year}';
    }
  }

  // Helper function to generate a color from text
  Color _generateColorFromText(String text) {
    final hash = text.hashCode;
    // Generate a pastel color by using lower saturation and higher lightness
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.8).toColor();
  }
}