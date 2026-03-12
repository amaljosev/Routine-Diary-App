import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/presentation/blocs/diary/diary_bloc.dart';

Future<void> showDeleteEntryDialog(
  BuildContext context,
  DiaryEntryModel entry,
) async {
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Delete Entry',
        style:
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Are you sure you want to delete this diary entry? '
        'This action cannot be undone.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: TextButton.styleFrom(
            foregroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<DiaryBloc>().add(DeleteDiaryEntry(entry.id));
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.redAccent,
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}