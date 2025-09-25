import 'package:consist/core/widgets/loading_widget.dart';
import 'package:consist/features/habit/domain/create_habit/entities/habit_model.dart';
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
    _loadHabits();
  }

  void _loadHabits() {
    context.read<HabitsBloc>().add( LoadHabitsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<HabitsBloc, HabitsState>(
        listener: (BuildContext context, HabitsState state) {
          // Handle state changes if needed
        },
        builder: (BuildContext context, HabitsState state) {
          return _buildBody(state, theme, isDark, size);
        },
      ),
      floatingActionButton: NewRoutine(isDark: isDark),
    );
  }

  Widget _buildBody(
    HabitsState state,
    ThemeData theme,
    bool isDark,
    Size size,
  ) {
    if (state is HabitsLoading) {
      return const AppLoading();
    }

    if (state is HabitsLoaded) {
      final List<Habit> habits = state.filtered;
      final List<Habit> allHabits = state.habits;
      final String selectedCategoryId = state.cat;

      if (allHabits.isEmpty) {
        return const HabitLibrary(fromHome: false);
      }

      return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => [
          _buildHeader(size, theme),
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
    }

    if (state is HabitsError) {
      return Center(child: Text('Error: ${state.message}'));
    }

    return const Center(
      child: Text('Welcome! Add a habit to get started.'),
    );
  }

  SliverAppBar _buildHeader(Size size, ThemeData theme) {
    return SliverAppBar.large(
      expandedHeight: size.height * 0.15,
      backgroundColor: theme.colorScheme.surface,
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
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'for today',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        expandedTitleScale: 1.0,
        stretchModes: const [StretchMode.zoomBackground],
      ),
      title: Text(
        'Small steps, big results. Keep going!',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      pinned: true,
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