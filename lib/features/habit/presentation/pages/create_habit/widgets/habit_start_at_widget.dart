import 'package:consist/features/habit/presentation/pages/create_habit/bloc/create_bloc.dart';
import 'package:consist/features/habit/presentation/pages/create_habit/widgets/habit_create_tile.dart';
import 'package:consist/features/habit/presentation/widgets/calender_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitStartAtWidget extends StatelessWidget {
  const HabitStartAtWidget({
    super.key,
    required this.habitStartAt,
    required this.isDark,
  });

  final DateTime? habitStartAt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return HabitCreationTile(
      icon: Icons.calendar_month,
      title: 'Start Date',
      trailing: habitStartAt != null
          ? '${habitStartAt?.day}-${habitStartAt?.month}-${habitStartAt?.year}'
          : 'Today',
      onTap: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) => Container(
          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CalenderWidget(
                  isHome: false,
                  showHeader: true,
                  onDaySelected: (date, _) {
                    context.read<CreateBloc>().add(
                      UpdateHabitStartAtEvent(date.toString()),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}