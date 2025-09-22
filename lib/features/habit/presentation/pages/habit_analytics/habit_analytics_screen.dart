import 'package:consist/core/utils/converters.dart';
import 'package:consist/core/widgets/error_widget.dart';
import 'package:consist/core/widgets/loading_widget.dart';
import 'package:consist/features/habit/domain/create_habit/entities/analytics_models.dart';
import 'package:consist/features/habit/presentation/blocs/habits_bloc/habits_bloc.dart';
import 'package:consist/features/habit/presentation/widgets/calender_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class HabitAnalyticsScreen extends StatefulWidget {
  final String habitId;
  const HabitAnalyticsScreen({super.key, required this.habitId});

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HabitsBloc>().add(FetchHabitAnalyticsEvent(widget.habitId));
  }

  Map<int, int> _countDaysFrequency(List<int> days) {
    final countMap = <int, int>{};
    for (var d = 1; d <= 7; d++) {
      countMap[d] = 0;
    }
    for (var day in days) {
      if (countMap.containsKey(day)) {
        countMap[day] = (countMap[day] ?? 0) + 1;
      }
    }
    return countMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Habit Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<HabitsBloc>().add(LoadHabitsEvent());
          },
          icon: Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        builder: (context, state) {
          if (state is HabitAnalyticsLoading) {
            return const AppLoading();
          } else if (state is HabitAnalyticsError) {
            return ErrorScreenWidget();
          } else if (state is HabitAnalyticsLoaded) {
            final HabitAnalytics?  analytics = state.analytics;

            if (analytics == null) {
              return const Center(
                child: Text('No analytics found for this habit.'),
              );
            }

            final dayCounts = _countDaysFrequency(analytics.mostActiveDays);
            final maxDayCount = dayCounts.values.isEmpty
                ? 1
                : dayCounts.values.reduce((a, b) => a > b ? a : b);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.local_fire_department,
                            title: "Current Streak",
                            value: analytics.currentStreak.toString(),
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star,
                            title: "Best Streak",
                            value: analytics.bestStreak.toString(),
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.emoji_events,
                            title: "Stars Earned",
                            value: analytics.starsEarned.toString(),
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    //streak calender section
                    _buildSectionHeader("Streak Range"),
                    const SizedBox(height: 16),
                    _buildStreakCalender(
                      AppConverters.stringToDateTime(analytics.streakStartedAt),
                      AppConverters.stringToDateTime(analytics.lastDay),
                    ),
                    const SizedBox(height: 30),
                    // Completion Rates Progress Indicators
                    _buildSectionHeader("Completion Rates"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _modernCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          // _buildProgressRow(
                          //   label: "Today",
                          //   value: analytics.completionRate,
                          //   color: Colors.indigoAccent,
                          // ),
                          _buildProgressRow(
                            label: "Weekly",
                            value: analytics.weeklyCompletionRate,
                            color: Colors.tealAccent.shade700,
                          ),

                          _buildProgressRow(
                            label: "Monthly",
                            value: analytics.monthlyCompletionRate,
                            color: Colors.orange.shade400,
                          ),

                          _buildProgressRow(
                            label: "Yearly",
                            value: analytics.yearlyCompletionRate,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Most Active Days as Bar Chart
                    _buildSectionHeader("Most Active Days"),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: _modernCardDecoration(),
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),

                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxDayCount.toDouble() + 1,
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(),
                            leftTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const labels = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < labels.length) {
                                    return Text(
                                      labels[value.toInt()],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(7, (index) {
                            final dayIndex = index + 1;
                            final count = dayCounts[dayIndex]?.toDouble() ?? 0;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: count,
                                  color: Colors.indigoAccent,
                                  width: 20,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxDayCount.toDouble() + 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Achievements Section
                    _buildSectionHeader("Achievements"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: analytics.achievements.isEmpty
                          ? [const Chip(label: Text('No achievements yet'))]
                          : analytics.achievements
                                .map(
                                  (a) => Chip(
                                    label: Text("Achievement #$a"),
                                    backgroundColor: Colors.green.shade50,
                                    avatar: const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Loading analytics...'));
        },
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              minHeight: 14,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "${value.toStringAsFixed(0)}%",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Modern Stat Card widget
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _modernCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),

          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),

          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Section header widget
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900),
    );
  }

  // Card decoration with shadow & rounded corners
  BoxDecoration _modernCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    );
  }

  _buildStreakCalender(DateTime? streakStartedAt, DateTime? lastUpdated) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _modernCardDecoration(),
      child: HabitAnalyticsCalendarWidget(
        rangeStartDay: streakStartedAt,
        rangeEndDay: streakStartedAt != null ? lastUpdated : null,
        showHeader: true,
      ),
    );
  }
}
