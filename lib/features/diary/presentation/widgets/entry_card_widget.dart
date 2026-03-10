import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/utils/converters.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';
import 'package:routine/features/diary/presentation/pages/preview/diary_preview.dart';

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntryModel entry;

  const DiaryEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = theme.colorScheme.primary;
    final colorD = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.6)
            : theme.colorScheme.surface,
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
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withValues(alpha: 0.1)
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
                        style: theme.textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : colorD,
                        ),
                      ),
                      Text(
                        _getMonth(entry.date),
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.8)
                              : colorD.withValues(alpha: 0.5),
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
                                  ? theme.colorScheme.onSurface.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Hero(
                              tag: 'moodTag${entry.id}',
                              child: Text(
                                entry.mood,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Title
                          Expanded(
                            child: Text(
                              entry.title.isEmpty ? "Untitled" : entry.title,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontFamily: entry.fontFamily,
                              ),
                              maxLines: 1,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontFamily: entry.fontFamily,
                          ),
                        )
                      else
                        Text(
                          "No content yet...",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
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
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            getRelativeDateLabel(entry.date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
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
      case 1:
        return 'JAN';
      case 2:
        return 'FEB';
      case 3:
        return 'MAR';
      case 4:
        return 'APR';
      case 5:
        return 'MAY';
      case 6:
        return 'JUN';
      case 7:
        return 'JUL';
      case 8:
        return 'AUG';
      case 9:
        return 'SEP';
      case 10:
        return 'OCT';
      case 11:
        return 'NOV';
      case 12:
        return 'DEC';
      default:
        return newDate.month.toString().padLeft(2, '0');
    }
  }

  String getRelativeDateLabel(String dateString) {
    try {
      final DateTime entryDate = DateTime.parse(dateString).toLocal();
      final DateTime now = DateTime.now();

      final DateTime entryDateOnly = DateTime(
        entryDate.year,
        entryDate.month,
        entryDate.day,
      );
      final DateTime nowDateOnly = DateTime(now.year, now.month, now.day);

      final int difference = nowDateOnly.difference(entryDateOnly).inDays;

      // Future dates handling (optional)
      if (difference < 0) {
        return _formatDate(entryDateOnly);
      }

      if (difference == 0) {
        return "Today";
      }

      if (difference == 1) {
        return "Yesterday";
      }

      // Up to 7 days
      if (difference <= 7) {
        return "$difference days ago";
      }

      // Weeks (up to 4 weeks)
      if (difference < 30) {
        final weeks = (difference / 7).floor();
        return weeks == 1 ? "1 week ago" : "$weeks weeks ago";
      }

      // Months (up to 12 months)
      if (difference < 365) {
        final months = (difference / 30).floor();
        return months == 1 ? "1 month ago" : "$months months ago";
      }

      // Older than 1 year → return formatted date
      return _formatDate(entryDateOnly);
    } catch (e) {
      return "";
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return "$day/$month/$year";
  }

}
