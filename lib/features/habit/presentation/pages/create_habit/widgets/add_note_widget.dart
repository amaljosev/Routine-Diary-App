import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_create_tile.dart';
import 'package:flutter/material.dart';

class AddNoteWidget extends StatefulWidget {
  const AddNoteWidget({
    super.key,
    required this.isDark,
    required this.noteController,
  });

  final bool isDark;
  final TextEditingController noteController;

  @override
  State<AddNoteWidget> createState() => _AddNoteWidgetState();
}

class _AddNoteWidgetState extends State<AddNoteWidget> {
  bool _hasNote = false;

  @override
  void initState() {
    super.initState();
    _hasNote = widget.noteController.text.trim().isNotEmpty;
    widget.noteController.addListener(_updateNoteStatus);
  }

  void _updateNoteStatus() {
    final hasText = widget.noteController.text.trim().isNotEmpty;
    if (_hasNote != hasText) {
      setState(() {
        _hasNote = hasText;
      });
    }
  }

  @override
  void dispose() {
    widget.noteController.removeListener(_updateNoteStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.isDark ? Colors.black26 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: HabitCreationTile(
          icon: Icons.book_outlined,
          title: _hasNote ? 'Update Note' : 'Add Note',
          trailing: null,
          onTap: () async {
            final result = await showNoteDialog(context, widget.noteController);
            if (result && mounted) {
              setState(() {
                _hasNote = widget.noteController.text.trim().isNotEmpty;
              });
            }
          },
        ),
      ),
    );
  }
}

Future<bool> showNoteDialog(
  BuildContext context,
  TextEditingController noteController,
) async {
  final formKey = GlobalKey<FormState>();
  final tempController = TextEditingController(text: noteController.text);

  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              noteController.text.trim().isEmpty ? 'Add Note' : 'Edit Note',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: tempController,
                maxLength: 100,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a note';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    noteController.text = tempController.text;
                    debugPrint('Note: ${noteController.text}');
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ) ??
      false;
}
