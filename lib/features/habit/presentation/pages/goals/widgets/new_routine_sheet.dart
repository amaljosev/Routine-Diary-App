import 'package:consist/features/habit/presentation/pages/create_habit/create_habit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewRoutine extends StatelessWidget {
  const NewRoutine({super.key, required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Create Custom Habit',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => NewGoalDetailWidget(isDark: isDark),
        );
      },
      child: Icon(Icons.add),
    );
  }
}

class NewGoalDetailWidget extends StatelessWidget {
  const NewGoalDetailWidget({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoutineTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateHabitScreen(habit: null, category: '1'),
                  ),
                ),
                title: 'Habits to Develop',
                subTitle: "Positive routines you want to build and stick with.",
                icon: Icons.flag,
              ),
              Divider(
                color: isDark ? Colors.white54 : Colors.blueGrey.shade100,
                height: 0,
              ),
              RoutineTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateHabitScreen(habit: null, category: '2'),
                  ),
                ),
                title: 'Habits to Quit',
                subTitle: "Unhealthy habits you’re working to break.",
                icon: Icons.dangerous_outlined,
              ),
              Divider(
                color: isDark ? Colors.white54 : Colors.blueGrey.shade100,
                height: 0,
              ),

              RoutineTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateHabitScreen(habit: null, category: '3'),
                  ),
                ),
                title: 'Task',
                subTitle: "One-off actions you want to complete just once.",
                icon: Icons.add_task_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoutineTile extends StatelessWidget {
  const RoutineTile({
    super.key,
    required this.title,
    required this.subTitle,
    required this.icon,
    this.onTap,
  });
  final String title;
  final String subTitle;
  final IconData icon;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      trailing: const CupertinoListTileChevron(),
      title: Text(title),
      subtitle: Text(subTitle),
      titleTextStyle: Theme.of(context).textTheme.headlineSmall,
      subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
      onTap: onTap,
    );
  }
}
