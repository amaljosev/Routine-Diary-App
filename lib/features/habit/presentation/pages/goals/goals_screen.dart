import 'package:consist/core/widgets/loading_widget.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/categories_slider.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/goal_list.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/new_routine_sheet.dart';
import 'package:consist/features/habit/presentation/pages/goals/widgets/no_habits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HabitsBloc>().add(LoadHabitsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<HabitsBloc, HabitsState>(
        listener: (context, state) {
          if (state is HabitCompleteSuccess) {
            context.read<HabitsBloc>().add(LoadHabitsEvent());
          }
        },
        builder: (context, state) {
          if (state is HabitsLoading) {
            return AppLoading();
          } else if (state is HabitsLoaded) {
            
            final habits = state.filtered;
            final allHabits = state.habits;
            final selectedCategoryId = state.cat;

            return allHabits.isEmpty
                ? const HabitLibrary(fromHome: false)
                : NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      header(size, context),
                      // Add the categories as a pinned sliver
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CategoriesSliverDelegate(
                          child: HabitCategoriesSlider(
                            selectedCategoryId: selectedCategoryId,
                          ),
                        ),
                      ),
                    ],
                    body: GoalsList(habits: habits, isDark: isDark, size: size),
                  );
          } else if (state is HabitsError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          return const Center(
            child: Text("Welcome! Add a habit to get started."),
          );
        },
      ),
      floatingActionButton: NewRoutine(isDark: isDark),
    );
  }
}

class _CategoriesSliverDelegate extends SliverPersistentHeaderDelegate {
  _CategoriesSliverDelegate({required this.child});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  double get maxExtent => 70.0;
  @override
  double get minExtent => 70.0;

  @override
  bool shouldRebuild(_CategoriesSliverDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

SliverAppBar header(Size size, BuildContext context) {
  return SliverAppBar.large(
    expandedHeight: size.height * 0.15,
    backgroundColor: Theme.of(context).colorScheme.surface,
    flexibleSpace: FlexibleSpaceBar(
      background: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Goals',
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'for today',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium!.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      expandedTitleScale: 1.0,
      stretchModes: [StretchMode.zoomBackground],
    ),
    title: Text(
      'Small steps, big results. Keep going!',
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    centerTitle: true,
    automaticallyImplyLeading: false,
    elevation: 0,
    pinned: true,
  );
}
